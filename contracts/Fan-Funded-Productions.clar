;; title: Fan-Funded-Productions
;; version: 1.0.0
;; summary: Crowdfund creative productions and distribute profits to token holders
;; description: A decentralized platform for funding music videos and comedy specials with automated profit sharing



(define-fungible-token production-token)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_CAMPAIGN_NOT_FOUND (err u102))
(define-constant ERR_CAMPAIGN_ENDED (err u103))
(define-constant ERR_CAMPAIGN_NOT_FUNDED (err u104))
(define-constant ERR_ALREADY_CLAIMED (err u105))
(define-constant ERR_INSUFFICIENT_FUNDS (err u106))
(define-constant ERR_CAMPAIGN_ACTIVE (err u107))
(define-constant ERR_INVALID_DEADLINE (err u108))

(define-data-var next-campaign-id uint u1)
(define-data-var total-revenue uint u0)

(define-map campaigns 
  uint 
  {
    creator: principal,
    title: (string-ascii 64),
    description: (string-ascii 256),
    funding-goal: uint,
    current-funding: uint,
    deadline: uint,
    is-funded: bool,
    total-tokens: uint,
    revenue-per-token: uint,
    is-active: bool
  }
)

(define-map campaign-backers 
  {campaign-id: uint, backer: principal}
  {amount: uint, tokens: uint, claimed: bool}
)

(define-map user-campaigns principal (list 50 uint))

(define-public (get-name)
  (ok "Fan-Funded Productions Token")
)

(define-public (get-symbol)
  (ok "FFP")
)

(define-public (get-decimals)
  (ok u6)
)

(define-public (get-balance (who principal))
  (ok (ft-get-balance production-token who))
)

(define-public (get-total-supply)
  (ok (ft-get-supply production-token))
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
    (ft-transfer? production-token amount sender recipient)
  )
)

(define-public (create-campaign (title (string-ascii 64)) (description (string-ascii 256)) (funding-goal uint) (deadline uint))
  (let 
    (
      (campaign-id (var-get next-campaign-id))
      (current-block stacks-block-height)
    )
    (asserts! (> funding-goal u0) ERR_INVALID_AMOUNT)
    (asserts! (> deadline current-block) ERR_INVALID_DEADLINE)
    
    (map-set campaigns campaign-id {
      creator: tx-sender,
      title: title,
      description: description,
      funding-goal: funding-goal,
      current-funding: u0,
      deadline: deadline,
      is-funded: false,
      total-tokens: u0,
      revenue-per-token: u0,
      is-active: true
    })
    
    (map-set user-campaigns tx-sender 
      (unwrap! (as-max-len? (append (default-to (list) (map-get? user-campaigns tx-sender)) campaign-id) u50) ERR_INVALID_AMOUNT)
    )
    
    (var-set next-campaign-id (+ campaign-id u1))
    (ok campaign-id)
  )
)

(define-public (fund-campaign (campaign-id uint) (amount uint))
  (let 
    (
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
      (current-block stacks-block-height)
      (backer-key {campaign-id: campaign-id, backer: tx-sender})
      (existing-backing (default-to {amount: u0, tokens: u0, claimed: false} (map-get? campaign-backers backer-key)))
    )
    (asserts! (get is-active campaign) ERR_CAMPAIGN_ENDED)
    (asserts! (< current-block (get deadline campaign)) ERR_CAMPAIGN_ENDED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (let 
      (
        (new-current-funding (+ (get current-funding campaign) amount))
        (new-backer-amount (+ (get amount existing-backing) amount))
        (tokens-issued amount)
      )
      
      (map-set campaigns campaign-id (merge campaign {
        current-funding: new-current-funding,
        is-funded: (>= new-current-funding (get funding-goal campaign)),
        total-tokens: (+ (get total-tokens campaign) tokens-issued)
      }))
      
      (map-set campaign-backers backer-key {
        amount: new-backer-amount,
        tokens: (+ (get tokens existing-backing) tokens-issued),
        claimed: false
      })
      
      (try! (ft-mint? production-token tokens-issued tx-sender))
      (ok tokens-issued)
    )
  )
)

(define-public (withdraw-funds (campaign-id uint))
  (let 
    (
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_UNAUTHORIZED)
    (asserts! (get is-funded campaign) ERR_CAMPAIGN_NOT_FUNDED)
    (asserts! (get is-active campaign) ERR_CAMPAIGN_ENDED)
    
    (try! (as-contract (stx-transfer? (get current-funding campaign) tx-sender (get creator campaign))))
    
    (map-set campaigns campaign-id (merge campaign {is-active: false}))
    (ok (get current-funding campaign))
  )
)

(define-public (refund-campaign (campaign-id uint))
  (let 
    (
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
      (current-block stacks-block-height)
      (backer-key {campaign-id: campaign-id, backer: tx-sender})
      (backing (unwrap! (map-get? campaign-backers backer-key) ERR_UNAUTHORIZED))
    )
    (asserts! (not (get is-funded campaign)) ERR_CAMPAIGN_ACTIVE)
    (asserts! (>= current-block (get deadline campaign)) ERR_CAMPAIGN_ACTIVE)
    (asserts! (not (get claimed backing)) ERR_ALREADY_CLAIMED)
    
    (try! (as-contract (stx-transfer? (get amount backing) tx-sender tx-sender)))
    (try! (ft-burn? production-token (get tokens backing) tx-sender))
    
    (map-set campaign-backers backer-key (merge backing {claimed: true}))
    (ok (get amount backing))
  )
)

(define-public (distribute-revenue (campaign-id uint) (revenue-amount uint))
  (let 
    (
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_UNAUTHORIZED)
    (asserts! (get is-funded campaign) ERR_CAMPAIGN_NOT_FUNDED)
    (asserts! (> revenue-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> (get total-tokens campaign) u0) ERR_INVALID_AMOUNT)
    
    (let 
      (
        (revenue-per-token (/ revenue-amount (get total-tokens campaign)))
      )
      (map-set campaigns campaign-id (merge campaign {
        revenue-per-token: (+ (get revenue-per-token campaign) revenue-per-token)
      }))
      
      (var-set total-revenue (+ (var-get total-revenue) revenue-amount))
      (ok revenue-per-token)
    )
  )
)

(define-public (claim-revenue (campaign-id uint))
  (let 
    (
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
      (backer-key {campaign-id: campaign-id, backer: tx-sender})
      (backing (unwrap! (map-get? campaign-backers backer-key) ERR_UNAUTHORIZED))
      (tokens-owned (get tokens backing))
      (revenue-per-token (get revenue-per-token campaign))
    )
    (asserts! (not (get claimed backing)) ERR_ALREADY_CLAIMED)
    (asserts! (> tokens-owned u0) ERR_INVALID_AMOUNT)
    (asserts! (> revenue-per-token u0) ERR_INVALID_AMOUNT)
    
    (let 
      (
        (total-payout (* tokens-owned revenue-per-token))
      )
      (try! (as-contract (stx-transfer? total-payout tx-sender tx-sender)))
      
      (map-set campaign-backers backer-key (merge backing {claimed: true}))
      (ok total-payout)
    )
  )
)

(define-public (close-campaign (campaign-id uint))
  (let 
    (
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_UNAUTHORIZED)
    (asserts! (>= current-block (get deadline campaign)) ERR_CAMPAIGN_ACTIVE)
    
    (map-set campaigns campaign-id (merge campaign {is-active: false}))
    (ok true)
  )
)

(define-read-only (get-campaign (campaign-id uint))
  (map-get? campaigns campaign-id)
)

(define-read-only (get-campaign-backing (campaign-id uint) (backer principal))
  (map-get? campaign-backers {campaign-id: campaign-id, backer: backer})
)

(define-read-only (get-user-campaigns (user principal))
  (default-to (list) (map-get? user-campaigns user))
)

(define-read-only (get-campaign-stats (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (ok {
      funding-progress: (/ (* (get current-funding campaign) u100) (get funding-goal campaign)),
      tokens-issued: (get total-tokens campaign),
      is-funded: (get is-funded campaign),
      blocks-remaining: (if (> (get deadline campaign) stacks-block-height) 
                         (- (get deadline campaign) stacks-block-height) 
                         u0)
    })
    ERR_CAMPAIGN_NOT_FOUND
  )
)

(define-read-only (get-total-campaigns)
  (- (var-get next-campaign-id) u1)
)

(define-read-only (get-contract-stats)
  (ok {
    total-campaigns: (get-total-campaigns),
    total-revenue: (var-get total-revenue),
    total-token-supply: (ft-get-supply production-token)
  })
)

(define-read-only (calculate-potential-payout (campaign-id uint) (backer principal))
  (match (map-get? campaigns campaign-id)
    campaign 
      (match (map-get? campaign-backers {campaign-id: campaign-id, backer: backer})
        backing (ok (* (get tokens backing) (get revenue-per-token campaign)))
        ERR_UNAUTHORIZED
      )
    ERR_CAMPAIGN_NOT_FOUND
  )
)

(define-public (emergency-pause (campaign-id uint))
  (let 
    (
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
    )
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender (get creator campaign))) ERR_UNAUTHORIZED)
    
    (map-set campaigns campaign-id (merge campaign {is-active: false}))
    (ok true)
  )
)

(define-read-only (get-campaign-timeline (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign 
      (let 
        (
          (current-block stacks-block-height)
          (deadline (get deadline campaign))
        )
        (ok {
          current-block: current-block,
          deadline: deadline,
          blocks-remaining: (if (> deadline current-block) (- deadline current-block) u0),
          is-expired: (>= current-block deadline)
        })
      )
    ERR_CAMPAIGN_NOT_FOUND
  )
)

(define-public (batch-fund-campaigns (campaigns-data (list 10 {campaign-id: uint, amount: uint})))
  (ok (map fund-single-campaign campaigns-data))
)

(define-private (fund-single-campaign (data {campaign-id: uint, amount: uint}))
  (fund-campaign (get campaign-id data) (get amount data))
)

(define-read-only (get-active-campaigns)
  (ok (filter is-campaign-active (enumerate-campaigns)))
)

(define-private (enumerate-campaigns)
  (map get-campaign-id (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20))
)

(define-private (get-campaign-id (id uint))
  id
)

(define-private (is-campaign-active (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    campaign (and (get is-active campaign) (< stacks-block-height (get deadline campaign)))
    false
  )
)

(define-read-only (get-funding-leaderboard (campaign-id uint))
  (ok (list))
)

(define-public (update-campaign-description (campaign-id uint) (new-description (string-ascii 256)))
  (let 
    (
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_UNAUTHORIZED)
    (asserts! (get is-active campaign) ERR_CAMPAIGN_ENDED)
    
    (map-set campaigns campaign-id (merge campaign {description: new-description}))
    (ok true)
  )
)

(define-read-only (get-backer-portfolio (backer principal))
  (ok {
    total-invested: u0,
    total-tokens: (ft-get-balance production-token backer),
    campaigns-backed: (len (default-to (list) (map-get? user-campaigns backer)))
  })
)
