;; --------------------------------------------------
;; STACK-FUND-DAO CONTRACT
;; Complex Clarity Contract combining DAO, Staking, and Crowdfunding
;; --------------------------------------------------

(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-NOT-ENOUGH-STX (err u103))
(define-constant ERR-NOT-CREATOR (err u104))
(define-constant ERR-MILESTONE-NOT-READY (err u105))
(define-constant ERR-VOTING-CLOSED (err u106))

(define-data-var project-count uint u0)
(define-map projects
  { project-id: uint }
  { creator: principal, goal: uint, raised: uint, milestone-count: uint, current-milestone: uint, completed: bool }
)

(define-map milestones
  { project-id: uint, milestone-id: uint }
  { description: (string-ascii 100),
    amount: uint,
    approved: bool,
    released: bool }
)

(define-map backers
  { project-id: uint, user: principal }
  { amount: uint }
)

(define-map stakes
  { user: principal }
  { amount: uint,
    reputation: uint }
)

(define-map votes
  { project-id: uint, milestone-id: uint, user: principal }
  { vote: bool }
)

;; --------------------------------------------------
;; UTILITIES
;; --------------------------------------------------

(define-private (only-creator (project-id uint))
  (let (
        (project (map-get? projects { project-id: project-id }))
       )
    (if (is-some project)
        (let ((data (unwrap! project ERR-NOT-FOUND)))
          (asserts! (is-eq tx-sender (get creator data)) ERR-NOT-CREATOR)
          (ok true))
        (err u999)
    )
  )
)

;; --------------------------------------------------
;; DAO + STAKING LOGIC
;; --------------------------------------------------

(define-public (stake (amount uint))
  (begin
    (let ((transfer (stx-transfer? amount tx-sender (as-contract tx-sender))))
      (asserts! (is-ok transfer) ERR-NOT-ENOUGH-STX))
    (let ((user (map-get? stakes { user: tx-sender })))
      (if (is-some user)
          (let ((old (unwrap! user ERR-NOT-FOUND)))
            (map-set stakes { user: tx-sender }
              {
                amount: (+ (get amount old) amount),
                reputation: (+ (get reputation old) (/ amount u100))
              }
            ))
          (map-set stakes { user: tx-sender }
            {
              amount: amount,
              reputation: (/ amount u100)
            }
          )
      )
    )
    (ok "Staked successfully")
  )
)

(define-read-only (get-reputation (user principal))
  (get reputation (default-to { amount: u0, reputation: u0 } (map-get? stakes { user: user })))
)

;; --------------------------------------------------
;; PROJECT CREATION + BACKING
;; --------------------------------------------------

(define-public (create-project (goal uint) (milestone-count uint))
  (begin
    (var-set project-count (+ (var-get project-count) u1))
    (map-set projects
      { project-id: (var-get project-count) }
      {
        creator: tx-sender,
        goal: goal,
        raised: u0,
        milestone-count: milestone-count,
        current-milestone: u0,
        completed: false
      }
    )
    (ok (var-get project-count))
  )
)

(define-public (add-milestone (project-id uint) (milestone-id uint) (description (string-ascii 100)) (amount uint))
  (begin
    (try! (only-creator project-id))
    (map-set milestones
      { project-id: project-id, milestone-id: milestone-id }
      {
        description: description,
        amount: amount,
        approved: false,
        released: false
      }
    )
    (ok "Milestone added")
  )
)
(define-public (back-project (project-id uint) (amount uint))
  (let (
        (project (unwrap! (map-get? projects { project-id: project-id }) ERR-NOT-FOUND))
       )
    (asserts! (<= (+ (get raised project) amount) (get goal project)) ERR-NOT-ENOUGH-STX)
    (let ((transfer (stx-transfer? amount tx-sender (as-contract tx-sender))))
      (asserts! (is-ok transfer) ERR-NOT-ENOUGH-STX))
    (map-set backers { project-id: project-id, user: tx-sender }
      { amount: amount }
    )
    (map-set projects { project-id: project-id }
      (merge project { raised: (+ (get raised project) amount) })
    )
    (ok "Project backed successfully")
  )
)

;; --------------------------------------------------
;; DAO VOTING FOR MILESTONE RELEASE
;; --------------------------------------------------

(define-public (vote-milestone (project-id uint) (milestone-id uint) (approve bool))
  (let (
        (user-stake (map-get? stakes { user: tx-sender }))
        (milestone (unwrap! (map-get? milestones { project-id: project-id, milestone-id: milestone-id }) ERR-NOT-FOUND))
       )
    (asserts! (is-some user-stake) ERR-NOT-AUTHORIZED)
    (map-set votes { project-id: project-id, milestone-id: milestone-id, user: tx-sender }
      { vote: approve }
    )
    (ok "Vote recorded")
  )
)

(define-public (finalize-milestone (project-id uint) (milestone-id uint))
  (let (
        (milestone (unwrap! (map-get? milestones { project-id: project-id, milestone-id: milestone-id }) ERR-NOT-FOUND))
       )
    ;; In real DAO, tally votes with reputation weighting simplified here
    (map-set milestones { project-id: project-id, milestone-id: milestone-id }
      (merge milestone { approved: true })
    )
    (ok "Milestone approved")
  )
)

;; --------------------------------------------------
;; FUND RELEASE + REWARD SYSTEM
;; --------------------------------------------------

(define-public (release-funds (project-id uint) (milestone-id uint))
  (let (
        (project (unwrap! (map-get? projects { project-id: project-id }) ERR-NOT-FOUND))
        (milestone (unwrap! (map-get? milestones { project-id: project-id, milestone-id: milestone-id }) ERR-NOT-FOUND))
       )
    (begin
      (asserts! (is-eq tx-sender (get creator project)) ERR-NOT-CREATOR)
      (asserts! (is-eq (get approved milestone) true) ERR-MILESTONE-NOT-READY)
      (asserts! (is-ok (stx-transfer? (get amount milestone) (as-contract tx-sender) (get creator project))) ERR-NOT-ENOUGH-STX)
      (map-set milestones { project-id: project-id, milestone-id: milestone-id }
        (merge milestone { released: true })
      )
      (ok "Milestone funds released")
    )
  )
)
