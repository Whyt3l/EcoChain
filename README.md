# EcoChain - Environmental Impact Tracking Platform

A blockchain-based platform for tracking carbon offsets and environmental initiatives, enabling organizations to earn carbon credits through verified sustainability efforts.

## Features

- Carbon offset tracking and verification
- Environmental initiative certification
- Automated carbon credit calculation
- Transparent sustainability metrics
- Decentralized environmental governance

## Smart Contract Functions

### Public Functions
- `launch-eco-program` - Initialize the environmental tracking program
- `certify-initiative` - Approve environmental initiatives for tracking
- `record-carbon-offset` - Log carbon offset achievements
- `calculate-carbon-credits` - Compute earned carbon credits
- `claim-eco-rewards` - Claim environmental rewards

### Read-Only Functions
- `get-carbon-offset` - View organization's carbon offset
- `get-organization-initiative` - Get organization's current initiative
- `get-total-carbon-offset` - View total platform carbon offset
- `is-initiative-certified` - Check initiative certification status
- `get-program-metrics` - View platform statistics

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Initialize with `launch-eco-program`
3. Certify environmental initiatives
4. Start tracking carbon offsets
5. Claim rewards based on contributions

## License

MIT License
\`\`\`

```clarity file="project-2-skillforge/contracts/skillforge.clar"
;; SkillForge - Professional skill development and certification platform
;; Version: 1.0.0

(define-data-var training-administrator principal tx-sender)
(define-data-var total-skill-points uint u0)
(define-data-var certification-multiplier uint u30) ;; certification points per skill point
(define-data-var last-certification-round uint u0)

(define-map developer-skills principal uint)
(define-map developer-specializations principal (string-utf8 64))
(define-map specialization-validations (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-admin (err u4200))
(define-constant err-admin-already-exists (err u4201))
(define-constant err-invalid-points (err u4202))
(define-constant err-no-certifications-due (err u4203))
(define-constant err-no-skills (err u4204))
(define-constant err-invalid-specialization (err u4205))
(define-constant err-specialization-not-validated (err u4206))

;; Verify administrator authorization
(define-private (is-training-administrator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get training-administrator)) err-unauthorized-admin)
    (ok true)))

;; Initialize skill development program
(define-public (launch-skill-program (administrator principal))
  (begin
    (asserts! (is-none (map-get? developer-skills administrator)) err-admin-already-exists)
    (var-set training-administrator administrator)
    (ok "SkillForge program launched successfully")))

;; Validate specialization for skill tracking
(define-public (validate-specialization (specialization-name (string-utf8 64)))
  (begin
    (try! (is-training-administrator tx-sender))
    (asserts! (> (len specialization-name) u0) err-invalid-specialization)
    (map-set specialization-validations specialization-name true)
    (ok "Specialization validated for skill tracking")))

;; Record skill development points
(define-public (record-skill-points (points uint) (specialization (string-utf8 64)))
  (begin
    (asserts! (> points u0) err-invalid-points)
    (asserts! (default-to false (map-get? specialization-validations specialization)) err-specialization-not-validated)
    
    (let ((current-points (default-to u0 (map-get? developer-skills tx-sender))))
      (map-set developer-skills tx-sender (+ current-points points))
      (map-set developer-specializations tx-sender specialization)
      (var-set total-skill-points (+ (var-get total-skill-points) points))
      (ok (+ current-points points)))))

;; Calculate certification points
(define-public (calculate-certification-points)
  (begin
    (try! (is-training-administrator tx-sender))
    (let ((current-round (+ (var-get last-certification-round) u1))
          (total-points (var-get total-skill-points)))
      (asserts! (> total-points (var-get last-certification-round)) err-no-certifications-due)
      
      (let ((new-certifications (* (var-get certification-multiplier) total-points)))
        (var-set last-certification-round current-round)
        (ok new-certifications)))))

;; Claim professional certifications
(define-public (claim-skill-certifications)
  (begin
    (let ((developer-points (default-to u0 (map-get? developer-skills tx-sender))))
      (asserts! (> developer-points u0) err-no-skills)
      
      (let ((total-points (var-get total-skill-points))
            (cert-points (* (var-get certification-multiplier) developer-points))
            (skill-percentage (/ (* developer-points u100000) total-points)))
        
        (let ((final-certification (/ (* skill-percentage cert-points) u100000)))
          (map-delete developer-skills tx-sender)
          (map-delete developer-specializations tx-sender)
          (var-set total-skill-points (- (var-get total-skill-points) developer-points))
          (ok (+ developer-points final-certification)))))))

;; Read-only functions
(define-read-only (get-skill-points (developer principal))
  (default-to u0 (map-get? developer-skills developer)))

(define-read-only (get-developer-specialization (developer principal))
  (map-get? developer-specializations developer))

(define-read-only (get-total-skill-points)
  (var-get total-skill-points))

(define-read-only (is-specialization-validated (specialization-name (string-utf8 64)))
  (default-to false (map-get? specialization-validations specialization-name)))

(define-read-only (get-program-overview)
  {
    administrator: (var-get training-administrator),
    total-points: (var-get total-skill-points),
    certification-multiplier: (var-get certification-multiplier)
  })
