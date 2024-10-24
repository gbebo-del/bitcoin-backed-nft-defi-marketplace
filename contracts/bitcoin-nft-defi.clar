;; Bitcoin-Backed NFT Marketplace with DeFi Elements

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-token (err u103))
(define-constant err-listing-not-found (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-insufficient-collateral (err u106))
(define-constant err-already-staked (err u107))
(define-constant err-not-staked (err u108))
(define-constant err-invalid-percentage (err u109))

;; Data Variables
(define-data-var min-collateral-ratio uint u150)  ;; 150% minimum collateral ratio
(define-data-var protocol-fee uint u25)           ;; 2.5% fee in basis points
(define-data-var total-staked uint u0)
(define-data-var yield-rate uint u50)             ;; 5% annual yield rate in basis points

;; Data Maps
(define-map tokens
    { token-id: uint }
    {
        owner: principal,
        uri: (string-ascii 256),
        collateral: uint,
        is-staked: bool,
        stake-timestamp: uint,
        fractional-shares: uint
    }
)

(define-map token-listings
    { token-id: uint }
    {
        price: uint,
        seller: principal,
        active: bool
    }
)

(define-map fractional-ownership
    { token-id: uint, owner: principal }
    { shares: uint }
)

(define-map staking-rewards
    { token-id: uint }
    { 
        accumulated-yield: uint,
        last-claim: uint
    }
)

;; NFT Core Functions
(define-public (mint-nft (uri (string-ascii 256)) (collateral uint))
    (let
        (
            (token-id (+ (var-get total-supply) u1))
            (collateral-requirement (/ (* (var-get min-collateral-ratio) collateral) u100))
        )
        (asserts! (>= (stx-get-balance tx-sender) collateral-requirement) err-insufficient-collateral)
        (try! (stx-transfer? collateral-requirement tx-sender (as-contract tx-sender)))
        (map-set tokens
            { token-id: token-id }
            {
                owner: tx-sender,
                uri: uri,
                collateral: collateral,
                is-staked: false,
                stake-timestamp: u0,
                fractional-shares: u0
            }
        )
        (var-set total-supply token-id)
        (ok token-id)
    )
)

(define-public (transfer-nft (token-id uint) (recipient principal))
    (let
        (
            (token (unwrap! (get-token-info token-id) err-invalid-token))
        )
        (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
        (asserts! (not (get is-staked token)) err-already-staked)
        (map-set tokens
            { token-id: token-id }
            (merge token { owner: recipient })
        )
        (ok true)
    )
)

;; Marketplace Functions
(define-public (list-nft (token-id uint) (price uint))
    (let
        (
            (token (unwrap! (get-token-info token-id) err-invalid-token))
        )
        (asserts! (> price u0) err-invalid-price)
        (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
        (asserts! (not (get is-staked token)) err-already-staked)
        (map-set token-listings
            { token-id: token-id }
            {
                price: price,
                seller: tx-sender,
                active: true
            }
        )
        (ok true)
    )
)

(define-public (purchase-nft (token-id uint))
    (let
        (
            (listing (unwrap! (get-listing token-id) err-listing-not-found))
            (price (get price listing))
            (seller (get seller listing))
            (fee (/ (* price (var-get protocol-fee)) u1000))
        )
        (asserts! (get active listing) err-listing-not-found)
        (asserts! (is-eq (get active listing) true) err-listing-not-found)
        
        ;; Transfer STX from buyer to seller
        (try! (stx-transfer? price tx-sender seller))
        ;; Transfer protocol fee
        (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))
        
        ;; Update token ownership
        (try! (transfer-nft token-id tx-sender))
        
        ;; Clear listing
        (map-set token-listings
            { token-id: token-id }
            {
                price: u0,
                seller: seller,
                active: false
            }
        )
        (ok true)
    )
)

;; Staking Functions
(define-public (stake-nft (token-id uint))
    (let
        (
            (token (unwrap! (get-token-info token-id) err-invalid-token))
        )
        (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
        (asserts! (not (get is-staked token)) err-already-staked)
        
        (map-set tokens
            { token-id: token-id }
            (merge token { 
                is-staked: true,
                stake-timestamp: block-height
            })
        )
        (map-set staking-rewards
            { token-id: token-id }
            {
                accumulated-yield: u0,
                last-claim: block-height
            }
        )
        (var-set total-staked (+ (var-get total-staked) u1))
        (ok true)
    )
)

(define-public (unstake-nft (token-id uint))
    (let
        (
            (token (unwrap! (get-token-info token-id) err-invalid-token))
            (rewards (unwrap! (get-staking-rewards token-id) err-not-staked))
        )
        (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
        (asserts! (get is-staked token) err-not-staked)
        
        ;; Calculate and distribute final rewards
        (try! (claim-staking-rewards token-id))
        
        (map-set tokens
            { token-id: token-id }
            (merge token { 
                is-staked: false,
                stake-timestamp: u0
            })
        )
        (var-set total-staked (- (var-get total-staked) u1))
        (ok true)
    )
)

;; Fractional Ownership Functions
(define-public (fractionalize-nft (token-id uint) (total-shares uint))
    (let
        (
            (token (unwrap! (get-token-info token-id) err-invalid-token))
        )
        (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
        (asserts! (> total-shares u0) err-invalid-percentage)
        
        (map-set tokens
            { token-id: token-id }
            (merge token { fractional-shares: total-shares })
        )
        
        ;; Assign all shares to the original owner
        (map-set fractional-ownership
            { token-id: token-id, owner: tx-sender }
            { shares: total-shares }
        )
        (ok true)
    )
)

(define-public (transfer-shares (token-id uint) (recipient principal) (share-amount uint))
    (let
        (
            (sender-shares (unwrap! (get-fractional-shares token-id tx-sender) err-insufficient-balance))
            (recipient-shares (default-to { shares: u0 } (get-fractional-shares token-id recipient)))
        )
        (asserts! (>= (get shares sender-shares) share-amount) err-insufficient-balance)
        
        ;; Update sender's shares
        (map-set fractional-ownership
            { token-id: token-id, owner: tx-sender }
            { shares: (- (get shares sender-shares) share-amount) }
        )
        
        ;; Update recipient's shares
        (map-set fractional-ownership
            { token-id: token-id, owner: recipient }
            { shares: (+ (get shares recipient-shares) share-amount) }
        )
        (ok true)
    )
)

;; Read-Only Functions
(define-read-only (get-token-info (token-id uint))
    (map-get? tokens { token-id: token-id })
)

(define-read-only (get-listing (token-id uint))
    (map-get? token-listings { token-id: token-id })
)

(define-read-only (get-fractional-shares (token-id uint) (owner principal))
    (map-get? fractional-ownership { token-id: token-id, owner: owner })
)

(define-read-only (get-staking-rewards (token-id uint))
    (map-get? staking-rewards { token-id: token-id })
)

(define-read-only (calculate-rewards (token-id uint))
    (let
        (
            (token (unwrap! (get-token-info token-id) err-invalid-token))
            (rewards (unwrap! (get-staking-rewards token-id) err-not-staked))
            (blocks-staked (- block-height (get stake-timestamp token)))
            (yield-per-block (/ (var-get yield-rate) u52560)) ;; Approximate blocks per year
            (new-rewards (* blocks-staked yield-per-block))
        )
        (ok (+ (get accumulated-yield rewards) new-rewards))
    )
)