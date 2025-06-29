;; BitStack Lending Protocol
;; Enables STX lending using Bitcoin as collateral

;; Contract Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_COLLATERAL (err u101))
(define-constant ERR_LOAN_NOT_FOUND (err u102))
(define-constant ERR_LOAN_ALREADY_EXISTS (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_LIQUIDATION_NOT_ALLOWED (err u105))
(define-constant ERR_INVALID_AMOUNT (err u106))
(define-constant ERR_LOAN_EXPIRED (err u107))
(define-constant ERR_REPAYMENT_FAILED (err u108))

;; Loan terms
(define-constant LIQUIDATION_RATIO u150) ;; 150% collateralization required
(define-constant INTEREST_RATE u5) ;; 5% annual interest
(define-constant LOAN_DURATION u52560) ;; ~1 year in blocks (assuming 10min blocks)
(define-constant MIN_LOAN_AMOUNT u1000000) ;; 1 STX minimum

;; Data Variables
(define-data-var next-loan-id uint u1)
(define-data-var total-stx-lent uint u0)
(define-data-var btc-stx-price uint u50000000) ;; Price in micro-STX per satoshi

;; Data Maps
(define-map loans
  uint
  {
    borrower: principal,
    stx-amount: uint,
    btc-collateral: uint,
    interest-rate: uint,
    start-block: uint,
    duration: uint,
    is-active: bool
  }
)

(define-map user-loans principal (list 50 uint))
(define-map btc-collateral-deposits principal uint)

;; Authorization map for contract functions
(define-map authorized-callers principal bool)

;; Read-only functions

(define-read-only (get-loan (loan-id uint))
  (map-get? loans loan-id)
)

(define-read-only (get-user-loans (user principal))
  (default-to (list) (map-get? user-loans user))
)

(define-read-only (get-btc-collateral (user principal))
  (default-to u0 (map-get? btc-collateral-deposits user))
)

(define-read-only (calculate-required-collateral (stx-amount uint))
  (let (
    (btc-value-needed (* stx-amount LIQUIDATION_RATIO))
    (btc-amount-needed (/ btc-value-needed (var-get btc-stx-price)))
  )
    (/ btc-amount-needed u100)
  )
)

(define-read-only (calculate-interest (principal-amount uint) (blocks-elapsed uint))
  (let (
    (annual-interest (* principal-amount INTEREST_RATE))
    (block-interest (/ annual-interest u52560))
    (total-interest (* block-interest blocks-elapsed))
  )
    (/ total-interest u100)
  )
)

(define-read-only (get-loan-status (loan-id uint))
  (match (map-get? loans loan-id)
    loan-data
    (let (
      (blocks-elapsed (- block-height (get start-block loan-data)))
      (interest-owed (calculate-interest (get stx-amount loan-data) blocks-elapsed))
      (total-owed (+ (get stx-amount loan-data) interest-owed))
      (is-expired (> blocks-elapsed (get duration loan-data)))
    )
      (ok {
        loan-data: loan-data,
        blocks-elapsed: blocks-elapsed,
        interest-owed: interest-owed,
        total-owed: total-owed,
        is-expired: is-expired
      })
    )
    ERR_LOAN_NOT_FOUND
  )
)

(define-read-only (get-contract-stats)
  {
    total-stx-lent: (var-get total-stx-lent),
    next-loan-id: (var-get next-loan-id),
    btc-stx-price: (var-get btc-stx-price)
  }
)

;; Private functions

(define-private (is-authorized (caller principal))
  (or 
    (is-eq caller CONTRACT_OWNER)
    (default-to false (map-get? authorized-callers caller))
  )
)

(define-private (update-user-loans (user principal) (loan-id uint))
  (let (
    (current-loans (get-user-loans user))
    (updated-loans (unwrap-panic (as-max-len? (append current-loans loan-id) u50)))
  )
    (map-set user-loans user updated-loans)
  )
)

(define-private (validate-btc-collateral (btc-amount uint) (stx-amount uint))
  (let (
    (collateral-value (* btc-amount (var-get btc-stx-price)))
    (required-value (* stx-amount LIQUIDATION_RATIO))
  )
    (>= collateral-value required-value)
  )
)

;; Public functions

;; Initialize contract (only owner)
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set authorized-callers CONTRACT_OWNER true)
    (ok true)
  )
)

;; Update BTC/STX price (authorized callers only)
(define-public (update-btc-price (new-price uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR_NOT_AUTHORIZED)
    (var-set btc-stx-price new-price)
    (ok true)
  )
)

;; Deposit BTC collateral (simulated - in practice would use Bitcoin integration)
(define-public (deposit-btc-collateral (btc-amount uint))
  (begin
    (asserts! (> btc-amount u0) ERR_INVALID_AMOUNT)
    ;; In a real implementation, this would verify Bitcoin transaction
    ;; For now, we simulate the deposit
    (let (
      (current-collateral (get-btc-collateral tx-sender))
      (new-collateral (+ current-collateral btc-amount))
    )
      (map-set btc-collateral-deposits tx-sender new-collateral)
      (ok new-collateral)
    )
  )
)

;; Create a new loan
(define-public (create-loan (stx-amount uint) (btc-collateral-amount uint))
  (let (
    (loan-id (var-get next-loan-id))
    (user-collateral (get-btc-collateral tx-sender))
  )
    (begin
      ;; Validate inputs
      (asserts! (>= stx-amount MIN_LOAN_AMOUNT) ERR_INVALID_AMOUNT)
      (asserts! (>= user-collateral btc-collateral-amount) ERR_INSUFFICIENT_COLLATERAL)
      (asserts! (validate-btc-collateral btc-collateral-amount stx-amount) ERR_INSUFFICIENT_COLLATERAL)
      (asserts! (is-none (map-get? loans loan-id)) ERR_LOAN_ALREADY_EXISTS)
      
      ;; Check contract has enough STX
      (asserts! (>= (stx-get-balance (as-contract tx-sender)) stx-amount) ERR_INSUFFICIENT_BALANCE)
      
      ;; Lock collateral
      (map-set btc-collateral-deposits 
        tx-sender 
        (- user-collateral btc-collateral-amount)
      )
      
      ;; Create loan record
      (map-set loans loan-id {
        borrower: tx-sender,
        stx-amount: stx-amount,
        btc-collateral: btc-collateral-amount,
        interest-rate: INTEREST_RATE,
        start-block: block-height,
        duration: LOAN_DURATION,
        is-active: true
      })
      
      ;; Update user loans list
      (update-user-loans tx-sender loan-id)
      
      ;; Transfer STX to borrower
      (try! (as-contract (stx-transfer? stx-amount tx-sender tx-sender)))
      
      ;; Update contract state
      (var-set next-loan-id (+ loan-id u1))
      (var-set total-stx-lent (+ (var-get total-stx-lent) stx-amount))
      
      (ok loan-id)
    )
  )
)

;; Repay loan
(define-public (repay-loan (loan-id uint))
  (match (map-get? loans loan-id)
    loan-data
    (let (
      (borrower (get borrower loan-data))
      (blocks-elapsed (- block-height (get start-block loan-data)))
      (interest-owed (calculate-interest (get stx-amount loan-data) blocks-elapsed))
      (total-owed (+ (get stx-amount loan-data) interest-owed))
      (collateral-amount (get btc-collateral loan-data))
    )
      (begin
        ;; Validate repayment
        (asserts! (is-eq tx-sender borrower) ERR_NOT_AUTHORIZED)
        (asserts! (get is-active loan-data) ERR_LOAN_NOT_FOUND)
        (asserts! (>= (stx-get-balance tx-sender) total-owed) ERR_INSUFFICIENT_BALANCE)
        
        ;; Transfer STX payment to contract
        (try! (stx-transfer? total-owed tx-sender (as-contract tx-sender)))
        
        ;; Return BTC collateral
        (let (
          (current-collateral (get-btc-collateral borrower))
          (new-collateral (+ current-collateral collateral-amount))
        )
          (map-set btc-collateral-deposits borrower new-collateral)
        )
        
        ;; Mark loan as inactive
        (map-set loans loan-id (merge loan-data { is-active: false }))
        
        ;; Update total lent
        (var-set total-stx-lent (- (var-get total-stx-lent) (get stx-amount loan-data)))
        
        (ok total-owed)
      )
    )
    ERR_LOAN_NOT_FOUND
  )
)

;; Liquidate undercollateralized loan
(define-public (liquidate-loan (loan-id uint))
  (match (map-get? loans loan-id)
    loan-data
    (let (
      (blocks-elapsed (- block-height (get start-block loan-data)))
      (collateral-value (* (get btc-collateral loan-data) (var-get btc-stx-price)))
      (interest-owed (calculate-interest (get stx-amount loan-data) blocks-elapsed))
      (total-owed (+ (get stx-amount loan-data) interest-owed))
      (collateral-ratio (/ collateral-value total-owed))
    )
      (begin
        ;; Check if liquidation is allowed
        (asserts! (get is-active loan-data) ERR_LOAN_NOT_FOUND)
        (asserts! 
          (or 
            (< collateral-ratio LIQUIDATION_RATIO)
            (> blocks-elapsed (get duration loan-data))
          ) 
          ERR_LIQUIDATION_NOT_ALLOWED
        )
        
        ;; Mark loan as inactive
        (map-set loans loan-id (merge loan-data { is-active: false }))
        
        ;; Transfer collateral to liquidator (simplified)
        ;; In practice, this would involve Bitcoin network operations
        
        ;; Update total lent
        (var-set total-stx-lent (- (var-get total-stx-lent) (get stx-amount loan-data)))
        
        (ok (get btc-collateral loan-data))
      )
    )
    ERR_LOAN_NOT_FOUND
  )
)

;; Withdraw BTC collateral (unused portion)
(define-public (withdraw-btc-collateral (amount uint))
  (let (
    (current-collateral (get-btc-collateral tx-sender))
  )
    (begin
      (asserts! (>= current-collateral amount) ERR_INSUFFICIENT_COLLATERAL)
      (asserts! (> amount u0) ERR_INVALID_AMOUNT)
      
      ;; In practice, this would initiate Bitcoin withdrawal
      (map-set btc-collateral-deposits tx-sender (- current-collateral amount))
      
      (ok amount)
    )
  )
)

;; Admin function to add STX liquidity
(define-public (add-liquidity (amount uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR_NOT_AUTHORIZED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok amount)
  )
)

;; Admin function to manage authorized callers
(define-public (set-authorized-caller (caller principal) (authorized bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set authorized-callers caller authorized)
    (ok true)
  )
)

;; Emergency pause function (owner only)
(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    ;; Implementation would add pause functionality
    (ok true)
  )
)