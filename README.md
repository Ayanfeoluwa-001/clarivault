# Clarivault — Stack-Fund DAO (Clarity contract)

Small crowdfunding + DAO + staking example contract written in Clarity.
This repository contains the `clarivault.clar` contract which manages projects, milestones, backers, staking, DAO voting, and milestone fund releases.

## Table of contents
- Summary
- Repo layout
- Prerequisites
- Setup
- Build / Compile / Test
- Contract API (public functions)
- Data structures (maps / vars)
- Usage examples (Clarinet console)
- Troubleshooting
- Contributing
- License

## Summary
Clarivault is a sample Clarity smart contract combining:
- Project creation + milestones
- Backers and fund contributions
- Staking with reputation
- DAO voting to approve milestones
- Releasing milestone funds to project creators

This README explains how to compile, test, and interact with the contract locally.

## Repo layout
- contracts/
  - clarivault.clar         — main Clarity contract
- clarinet.toml (optional) — Clarinet config if present
- package.json (optional)   — test / task scripts

## Prerequisites
- Node.js (16+ recommended) and npm (for project toolchain, optional)
- Clarinet CLI (for compiling & local testing)
  - Install via npm or follow Clarinet docs:
    - npm: `npm install -g clarinet` (or use local dev dependency)
- Git and PowerShell (Windows)

## Setup (Windows PowerShell)
1. Clone and open repo:
   - git clone <repo-url>
   - cd C:\Users\USER\Desktop\STACKS\OCTOMBER\clarivault
2. (Optional) Install node deps:
   - npm install

## Build / Compile / Test
- Compile / check contract:
  - clarinet check
- Run tests (if tests exist):
  - clarinet test
- Start an interactive console:
  - clarinet console

Run these from the project root (PowerShell):
```powershell
cd C:\Users\USER\Desktop\STACKS\OCTOMBER\clarivault
clarinet check
clarinet test
clarinet console
```

## Contract API (public functions)
Public functions included in the contract:

- create-project (goal uint) (milestone-count uint) -> (ok project-id)
  - Create a new project with funding goal and number of milestones.

- add-milestone (project-id uint) (milestone-id uint) (description (string-ascii 100)) (amount uint) -> (ok "Milestone added")
  - Creator adds a milestone for a project.

- back-project (project-id uint) (amount uint) -> (ok "Project backed successfully")
  - Back a project by transferring STX into the contract and updating raised amount.

- stake (amount uint) -> (ok "Staked successfully")
  - Stake STX into the contract and gain reputation (stored in stakes map).

- vote-milestone (project-id uint) (milestone-id uint) (approve bool) -> (ok "Vote recorded")
  - Stakeholders vote for milestone approval.

- finalize-milestone (project-id uint) (milestone-id uint) -> (ok "Milestone approved")
  - Mark milestone approved (simplified tally).

- release-funds (project-id uint) (milestone-id uint) -> (ok "Milestone funds released")
  - Release milestone funds to the project creator after approval and checks.

Read-only helper:
- get-reputation (user principal) -> uint

## Data structures (maps & vars)
Key state:
- project-count: uint (data var)
- projects (map): key (project-id uint) -> value tuple:
  - creator: principal
  - goal: uint
  - raised: uint
  - milestone-count: uint
  - current-milestone: uint
  - completed: bool

- milestones (map): key (project-id uint, milestone-id uint) -> value tuple:
  - description: (string-ascii 100)
  - amount: uint
  - approved: bool
  - released: bool

- backers (map): key (project-id uint, user principal) -> amount: uint
- stakes (map): key (user principal) -> (amount: uint, reputation: uint)
- votes (map): key (project-id uint, milestone-id uint, user principal) -> vote: bool

Note: `define-map` syntax must follow Clarity tuple-list forms:
(define-map name
  ((key1 type1) (key2 type2))
  ((val1 type1) (val2 type2)))

## Usage examples (Clarinet console)
Start console:
- clarinet console

Example calls inside Clarinet console:
- Create a project:
  (contract-call? .clarivault create-project u1000 u3)

- Add a milestone:
  (contract-call? .clarivault add-milestone u1 u0 "Phase 1" u300)

- Back a project:
  (contract-call? .clarivault back-project u1 u50)

- Stake:
  (contract-call? .clarivault stake u100)

- Vote on milestone:
  (contract-call? .clarivault vote-milestone u1 u0 true)

- Finalize milestone:
  (contract-call? .clarivault finalize-milestone u1 u0)

- Release funds:
  (contract-call? .clarivault release-funds u1 u0)

Adjust contract name `.clarivault` if different in your Clarinet config.

## Troubleshooting
- "invalid map definition" / parser errors:
  - Ensure `define-map` follows Clarity syntax:
    ```clarity
    (define-map my-map
      ((key1 uint) (key2 principal))
      ((val1 uint) (val2 bool)))
    ```
  - Do not use JSON/object brace style for `define-map` fields. Use tuple lists.

- "expected ',' separating key-value pairs in tuple":
  - Ensure tuple literals use the correct colon form and structure in calls/returns when constructing map values or merge literals.

- If Clarinet shows outdated results after fixes:
  - Save the file and re-run `clarinet check`.
  - Restart Clarinet/console if necessary.

- produce a ready-to-commit `README.md` patch,
- create unit tests for core flows (create-project, add-milestone, back-project),
- or generate example Clarinet test scripts. Which do you want next?
