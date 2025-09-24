;; EcoChain - Environmental impact tracking and carbon credit platform
;; Version: 1.0.0

(define-data-var sustainability-director principal tx-sender)
(define-data-var total-carbon-offset uint u0)
(define-data-var credit-rate uint u15) ;; credits per ton of CO2 offset
(define-data-var last-credit-cycle uint u0)

(define-map organization-offsets principal uint)
(define-map organization-initiatives principal (string-utf8 64))
(define-map initiative-certifications (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-director (err u3100))
(define-constant err-director-already-exists (err u3101))
(define-constant err-invalid-offset (err u3102))
(define-constant err-no-credits-due (err u3103))
(define-constant err-no-offsets (err u3104))
(define-constant err-invalid-initiative (err u3105))
(define-constant err-initiative-not-certified (err u3106))

;; Verify director authorization
(define-private (is-sustainability-director (caller principal))
  (begin
    (asserts! (is-eq caller (var-get sustainability-director)) err-unauthorized-director)
    (ok true)))

;; Initialize carbon offset program
(define-public (launch-eco-program (director principal))
  (begin
    (asserts! (is-none (map-get? organization-offsets director)) err-director-already-exists)
    (var-set sustainability-director director)
    (ok "EcoChain program launched successfully")))

;; Certify environmental initiative
(define-public (certify-initiative (initiative-name (string-utf8 64)))
  (begin
    (try! (is-sustainability-director tx-sender))
    (asserts! (> (len initiative-name) u0) err-invalid-initiative)
    (map-set initiative-certifications initiative-name true)
    (ok "Initiative certified for carbon tracking")))

;; Record carbon offset
(define-public (record-carbon-offset (tons-co2 uint) (initiative (string-utf8 64)))
  (begin
    (asserts! (> tons-co2 u0) err-invalid-offset)
    (asserts! (default-to false (map-get? initiative-certifications initiative)) err-initiative-not-certified)
    
    (let ((current-offset (default-to u0 (map-get? organization-offsets tx-sender))))
      (map-set organization-offsets tx-sender (+ current-offset tons-co2))
      (map-set organization-initiatives tx-sender initiative)
      (var-set total-carbon-offset (+ (var-get total-carbon-offset) tons-co2))
      (ok (+ current-offset tons-co2)))))

;; Calculate carbon credits
(define-public (calculate-carbon-credits)
  (begin
    (try! (is-sustainability-director tx-sender))
    (let ((current-cycle (+ (var-get last-credit-cycle) u1))
          (total-offset (var-get total-carbon-offset)))
      (asserts! (> total-offset (var-get last-credit-cycle)) err-no-credits-due)
      
      (let ((new-credits (* (var-get credit-rate) total-offset)))
        (var-set last-credit-cycle current-cycle)
        (ok new-credits)))))

;; Claim environmental rewards
(define-public (claim-eco-rewards)
  (begin
    (let ((org-offset (default-to u0 (map-get? organization-offsets tx-sender))))
      (asserts! (> org-offset u0) err-no-offsets)
      
      (let ((total-offset (var-get total-carbon-offset))
            (carbon-credits (* (var-get credit-rate) org-offset))
            (contribution-ratio (/ (* org-offset u100000) total-offset)))
        
        (let ((final-reward (/ (* contribution-ratio carbon-credits) u100000)))
          (map-delete organization-offsets tx-sender)
          (map-delete organization-initiatives tx-sender)
          (var-set total-carbon-offset (- (var-get total-carbon-offset) org-offset))
          (ok (+ org-offset final-reward)))))))

;; Read-only functions
(define-read-only (get-carbon-offset (organization principal))
  (default-to u0 (map-get? organization-offsets organization)))

(define-read-only (get-organization-initiative (organization principal))
  (map-get? organization-initiatives organization))

(define-read-only (get-total-carbon-offset)
  (var-get total-carbon-offset))

(define-read-only (is-initiative-certified (initiative-name (string-utf8 64)))
  (default-to false (map-get? initiative-certifications initiative-name)))

(define-read-only (get-program-metrics)
  {
    director: (var-get sustainability-director),
    total-offset: (var-get total-carbon-offset),
    credit-rate: (var-get credit-rate)
  })
