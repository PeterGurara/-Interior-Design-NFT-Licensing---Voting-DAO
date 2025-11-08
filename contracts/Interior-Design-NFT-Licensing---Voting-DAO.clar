(define-trait nft-trait
    ((get-last-token-id () (response uint uint))
     (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
     (get-owner (uint) (response (optional principal) uint))))

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-exists (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-insufficient-payment (err u104))
(define-constant err-already-voted (err u105))
(define-constant err-invalid-proposal (err u106))
(define-constant err-proposal-expired (err u107))
(define-constant err-already-licensed (err u108))
(define-constant err-auction-exists (err u109))
(define-constant err-auction-not-found (err u110))
(define-constant err-auction-ended (err u111))
(define-constant err-auction-active (err u112))
(define-constant err-bid-too-low (err u113))
(define-constant err-not-auction-owner (err u114))
(define-constant err-lending-exists (err u115))
(define-constant err-lending-not-found (err u116))
(define-constant err-not-lender (err u117))
(define-constant err-lending-active (err u118))
(define-constant err-lending-expired (err u119))

(define-non-fungible-token design-nft uint)

(define-data-var last-token-id uint u0)
(define-data-var dao-treasury uint u0)
(define-data-var proposal-counter uint u0)

(define-map design-metadata uint {
    title: (string-ascii 50),
    creator: principal,
    design-type: (string-ascii 20),
    ipfs-hash: (string-ascii 64),
    royalty-rate: uint,
    total-ratings: uint,
    rating-sum: uint
})

(define-map design-licenses uint {
    owner: principal,
    licensee: principal,
    license-fee: uint,
    commercial-use: bool,
    expiry-block: uint
})

(define-map marketplace-listings uint {
    price: uint,
    seller: principal,
    license-terms: bool
})

(define-map dao-proposals uint {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    votes-for: uint,
    votes-against: uint,
    voting-deadline: uint,
    executed: bool,
    proposal-type: (string-ascii 20)
})

(define-map user-votes {user: principal, proposal-id: uint} bool)

(define-map design-ratings {token-id: uint, rater: principal} uint)

(define-map royalty-splits uint {
    creator-percentage: uint,
    decorator-percentage: uint,
    vendor-percentage: uint,
    dao-percentage: uint
})

(define-map contest-submissions uint {
    contest-id: uint,
    designer: principal,
    submission-hash: (string-ascii 64),
    votes: uint
})

(define-map design-auctions uint {
    seller: principal,
    reserve-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    end-block: uint,
    settled: bool
})

(define-map auction-bids {auction-id: uint, bidder: principal} uint)

(define-map user-favorites {user: principal, token-id: uint} bool)

(define-map nft-lendings uint {
    lender: principal,
    borrower: (optional principal),
    collateral-amount: uint,
    lending-fee: uint,
    duration-blocks: uint,
    start-block: uint,
    active: bool
})

(define-public (mint-design-nft
    (title (string-ascii 50))
    (design-type (string-ascii 20))
    (ipfs-hash (string-ascii 64))
    (royalty-rate uint)
    (recipient principal))
    (let ((token-id (+ (var-get last-token-id) u1)))
        (try! (nft-mint? design-nft token-id recipient))
        (map-set design-metadata token-id {
            title: title,
            creator: tx-sender,
            design-type: design-type,
            ipfs-hash: ipfs-hash,
            royalty-rate: royalty-rate,
            total-ratings: u0,
            rating-sum: u0
        })
        (map-set royalty-splits token-id {
            creator-percentage: u70,
            decorator-percentage: u15,
            vendor-percentage: u10,
            dao-percentage: u5
        })
        (var-set last-token-id token-id)
        (ok token-id)))

(define-public (list-for-sale (token-id uint) (price uint) (license-terms bool))
    (let ((owner (unwrap! (nft-get-owner? design-nft token-id) (err u404))))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (is-none (map-get? marketplace-listings token-id)) err-listing-exists)
        (map-set marketplace-listings token-id {
            price: price,
            seller: tx-sender,
            license-terms: license-terms
        })
        (ok true)))

(define-public (purchase-design (token-id uint))
    (let ((listing (unwrap! (map-get? marketplace-listings token-id) err-listing-not-found))
          (price (get price listing))
          (seller (get seller listing))
          (metadata (unwrap! (map-get? design-metadata token-id) (err u404)))
          (royalty-rate (get royalty-rate metadata))
          (creator (get creator metadata))
          (royalty-amount (/ (* price royalty-rate) u100))
          (seller-amount (- price royalty-amount)))
        (try! (stx-transfer? price tx-sender seller))
        (try! (stx-transfer? royalty-amount seller creator))
        (try! (nft-transfer? design-nft token-id seller tx-sender))
        (map-delete marketplace-listings token-id)
        (ok true)))

(define-public (license-design 
    (token-id uint) 
    (license-fee uint) 
    (commercial-use bool) 
    (duration-blocks uint))
    (let ((owner (unwrap! (nft-get-owner? design-nft token-id) (err u404)))
          (expiry-block (+ stacks-block-height duration-blocks)))
        (asserts! (is-some (map-get? design-metadata token-id)) (err u404))
        (asserts! (is-none (map-get? design-licenses token-id)) err-already-licensed)
        (try! (stx-transfer? license-fee tx-sender owner))
        (map-set design-licenses token-id {
            owner: owner,
            licensee: tx-sender,
            license-fee: license-fee,
            commercial-use: commercial-use,
            expiry-block: expiry-block
        })
        (ok true)))

(define-public (rate-design (token-id uint) (rating uint))
    (let ((metadata (unwrap! (map-get? design-metadata token-id) (err u404)))
          (current-ratings (get total-ratings metadata))
          (current-sum (get rating-sum metadata)))
        (asserts! (and (>= rating u1) (<= rating u5)) (err u400))
        (asserts! (is-none (map-get? design-ratings {token-id: token-id, rater: tx-sender})) (err u409))
        (map-set design-ratings {token-id: token-id, rater: tx-sender} rating)
        (map-set design-metadata token-id (merge metadata {
            total-ratings: (+ current-ratings u1),
            rating-sum: (+ current-sum rating)
        }))
        (ok true)))

(define-public (create-dao-proposal 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (proposal-type (string-ascii 20))
    (voting-duration uint))
    (let ((proposal-id (+ (var-get proposal-counter) u1))
          (deadline (+ stacks-block-height voting-duration)))
        (map-set dao-proposals proposal-id {
            proposer: tx-sender,
            title: title,
            description: description,
            votes-for: u0,
            votes-against: u0,
            voting-deadline: deadline,
            executed: false,
            proposal-type: proposal-type
        })
        (var-set proposal-counter proposal-id)
        (ok proposal-id)))

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
    (let ((proposal (unwrap! (map-get? dao-proposals proposal-id) err-invalid-proposal)))
        (asserts! (< stacks-block-height (get voting-deadline proposal)) err-proposal-expired)
        (asserts! (is-none (map-get? user-votes {user: tx-sender, proposal-id: proposal-id})) err-already-voted)
        (map-set user-votes {user: tx-sender, proposal-id: proposal-id} true)
        (if vote-for
            (map-set dao-proposals proposal-id (merge proposal {
                votes-for: (+ (get votes-for proposal) u1)
            }))
            (map-set dao-proposals proposal-id (merge proposal {
                votes-against: (+ (get votes-against proposal) u1)
            })))
        (ok true)))

(define-public (submit-to-contest (contest-id uint) (submission-hash (string-ascii 64)))
    (let ((submission-id (+ (var-get last-token-id) u1)))
        (map-set contest-submissions submission-id {
            contest-id: contest-id,
            designer: tx-sender,
            submission-hash: submission-hash,
            votes: u0
        })
        (ok submission-id)))

(define-public (vote-contest-submission (submission-id uint))
    (let ((submission (unwrap! (map-get? contest-submissions submission-id) (err u404))))
        (map-set contest-submissions submission-id (merge submission {
            votes: (+ (get votes submission) u1)
        }))
        (ok true)))

(define-public (distribute-royalties (token-id uint) (total-amount uint))
    (let ((splits (unwrap! (map-get? royalty-splits token-id) (err u404)))
          (metadata (unwrap! (map-get? design-metadata token-id) (err u404)))
          (creator (get creator metadata))
          (creator-amount (/ (* total-amount (get creator-percentage splits)) u100))
          (dao-amount (/ (* total-amount (get dao-percentage splits)) u100)))
        (try! (stx-transfer? creator-amount tx-sender creator))
        (var-set dao-treasury (+ (var-get dao-treasury) dao-amount))
        (ok true)))

(define-public (start-auction 
    (token-id uint) 
    (reserve-price uint) 
    (duration-blocks uint))
    (let ((owner (unwrap! (nft-get-owner? design-nft token-id) (err u404)))
          (end-block (+ stacks-block-height duration-blocks)))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (is-none (map-get? design-auctions token-id)) err-auction-exists)
        (asserts! (is-none (map-get? marketplace-listings token-id)) err-listing-exists)
        (map-set design-auctions token-id {
            seller: tx-sender,
            reserve-price: reserve-price,
            current-bid: u0,
            highest-bidder: none,
            end-block: end-block,
            settled: false
        })
        (ok true)))

(define-public (place-bid (token-id uint) (bid-amount uint))
    (let ((auction (unwrap! (map-get? design-auctions token-id) err-auction-not-found))
          (current-bid (get current-bid auction))
          (highest-bidder (get highest-bidder auction))
          (reserve-price (get reserve-price auction))
          (end-block (get end-block auction)))
        (asserts! (< stacks-block-height end-block) err-auction-ended)
        (asserts! (not (get settled auction)) err-auction-ended)
        (asserts! (>= bid-amount reserve-price) err-bid-too-low)
        (asserts! (> bid-amount current-bid) err-bid-too-low)
        (if (is-some highest-bidder)
            (try! (stx-transfer? current-bid (as-contract tx-sender) (unwrap-panic highest-bidder)))
            true)
        (try! (stx-transfer? bid-amount tx-sender (as-contract tx-sender)))
        (map-set auction-bids {auction-id: token-id, bidder: tx-sender} bid-amount)
        (map-set design-auctions token-id (merge auction {
            current-bid: bid-amount,
            highest-bidder: (some tx-sender)
        }))
        (ok true)))

(define-public (settle-auction (token-id uint))
    (let ((auction (unwrap! (map-get? design-auctions token-id) err-auction-not-found))
          (seller (get seller auction))
          (current-bid (get current-bid auction))
          (highest-bidder (get highest-bidder auction))
          (end-block (get end-block auction))
          (metadata (unwrap! (map-get? design-metadata token-id) (err u404)))
          (royalty-rate (get royalty-rate metadata))
          (creator (get creator metadata)))
        (asserts! (>= stacks-block-height end-block) err-auction-active)
        (asserts! (not (get settled auction)) err-auction-ended)
        (if (is-some highest-bidder)
            (let ((winner (unwrap-panic highest-bidder))
                  (royalty-amount (/ (* current-bid royalty-rate) u100))
                  (seller-amount (- current-bid royalty-amount)))
                (try! (as-contract (stx-transfer? seller-amount tx-sender seller)))
                (try! (as-contract (stx-transfer? royalty-amount tx-sender creator)))
                (try! (nft-transfer? design-nft token-id seller winner))
                (map-set design-auctions token-id (merge auction {settled: true}))
                (ok true))
            (begin
                (map-delete design-auctions token-id)
                (ok false)))))

(define-public (cancel-auction (token-id uint))
    (let ((auction (unwrap! (map-get? design-auctions token-id) err-auction-not-found))
          (seller (get seller auction))
          (current-bid (get current-bid auction))
          (highest-bidder (get highest-bidder auction))
          (end-block (get end-block auction)))
        (asserts! (is-eq tx-sender seller) err-not-auction-owner)
        (asserts! (< stacks-block-height end-block) err-auction-ended)
        (asserts! (is-eq current-bid u0) err-auction-active)
        (map-delete design-auctions token-id)
        (ok true)))

(define-public (add-to-favorites (token-id uint))
    (begin
        (asserts! (is-some (map-get? design-metadata token-id)) (err u404))
        (map-set user-favorites {user: tx-sender, token-id: token-id} true)
        (ok true)))

(define-public (remove-from-favorites (token-id uint))
    (begin
        (map-delete user-favorites {user: tx-sender, token-id: token-id})
        (ok true)))

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id)))

(define-read-only (get-token-uri (token-id uint))
    (ok (some (get ipfs-hash (unwrap! (map-get? design-metadata token-id) (err u404))))))

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? design-nft token-id)))

(define-read-only (get-design-metadata (token-id uint))
    (ok (map-get? design-metadata token-id)))

(define-read-only (get-design-rating (token-id uint))
    (let ((metadata (unwrap! (map-get? design-metadata token-id) (err u404)))
          (total-ratings (get total-ratings metadata))
          (rating-sum (get rating-sum metadata)))
        (if (> total-ratings u0)
            (ok (some (/ rating-sum total-ratings)))
            (ok none))))

(define-read-only (get-dao-proposal (proposal-id uint))
    (ok (map-get? dao-proposals proposal-id)))

(define-read-only (get-marketplace-listing (token-id uint))
    (ok (map-get? marketplace-listings token-id)))

(define-read-only (get-license-info (token-id uint))
    (ok (map-get? design-licenses token-id)))

(define-read-only (get-dao-treasury)
    (ok (var-get dao-treasury)))

(define-read-only (get-contest-submission (submission-id uint))
    (ok (map-get? contest-submissions submission-id)))

(define-read-only (get-auction-info (token-id uint))
    (ok (map-get? design-auctions token-id)))

(define-read-only (get-bid-info (token-id uint) (bidder principal))
    (ok (map-get? auction-bids {auction-id: token-id, bidder: bidder})))

(define-read-only (is-auction-ended (token-id uint))
    (match (map-get? design-auctions token-id)
        auction (ok (>= stacks-block-height (get end-block auction)))
        (err u404)))

(define-read-only (is-design-favorited (user principal) (token-id uint))
    (ok (is-some (map-get? user-favorites {user: user, token-id: token-id}))))

(define-public (lend-nft (token-id uint) (collateral-amount uint) (lending-fee uint) (duration-blocks uint))
    (let ((owner (unwrap! (nft-get-owner? design-nft token-id) (err u404))))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (is-none (map-get? nft-lendings token-id)) err-lending-exists)
        (asserts! (is-none (map-get? marketplace-listings token-id)) err-listing-exists)
        (asserts! (is-none (map-get? design-auctions token-id)) err-auction-exists)
        (try! (stx-transfer? collateral-amount tx-sender (as-contract tx-sender)))
        (map-set nft-lendings token-id {
            lender: tx-sender,
            borrower: none,
            collateral-amount: collateral-amount,
            lending-fee: lending-fee,
            duration-blocks: duration-blocks,
            start-block: u0,
            active: false
        })
        (ok true)))

(define-public (borrow-nft (token-id uint))
    (let ((lending (unwrap! (map-get? nft-lendings token-id) err-lending-not-found))
          (lender (get lender lending))
          (collateral-amount (get collateral-amount lending))
          (lending-fee (get lending-fee lending))
          (duration-blocks (get duration-blocks lending)))
        (asserts! (not (get active lending)) err-lending-active)
        (try! (stx-transfer? lending-fee tx-sender lender))
        (try! (nft-transfer? design-nft token-id lender tx-sender))
        (map-set nft-lendings token-id (merge lending {
            borrower: (some tx-sender),
            start-block: stacks-block-height,
            active: true
        }))
        (ok true)))

(define-public (return-nft (token-id uint))
    (let ((lending (unwrap! (map-get? nft-lendings token-id) err-lending-not-found))
          (borrower (unwrap! (get borrower lending) err-lending-not-found))
          (lender (get lender lending))
          (collateral-amount (get collateral-amount lending))
          (start-block (get start-block lending))
          (duration-blocks (get duration-blocks lending)))
        (asserts! (is-eq tx-sender borrower) err-not-token-owner)
        (asserts! (get active lending) err-lending-not-found)
        (asserts! (<= (- stacks-block-height start-block) duration-blocks) err-lending-expired)
        (try! (nft-transfer? design-nft token-id tx-sender lender))
        (try! (as-contract (stx-transfer? collateral-amount tx-sender borrower)))
        (map-set nft-lendings token-id (merge lending {
            borrower: none,
            start-block: u0,
            active: false
        }))
        (ok true)))

(define-public (claim-collateral (token-id uint))
    (let ((lending (unwrap! (map-get? nft-lendings token-id) err-lending-not-found))
          (lender (get lender lending))
          (borrower (unwrap! (get borrower lending) err-lending-not-found))
          (collateral-amount (get collateral-amount lending))
          (start-block (get start-block lending))
          (duration-blocks (get duration-blocks lending)))
        (asserts! (is-eq tx-sender lender) err-not-lender)
        (asserts! (get active lending) err-lending-not-found)
        (asserts! (> (- stacks-block-height start-block) duration-blocks) err-lending-active)
        (try! (nft-transfer? design-nft token-id borrower lender))
        (try! (as-contract (stx-transfer? collateral-amount tx-sender lender)))
        (map-delete nft-lendings token-id)
        (ok true)))

(define-read-only (get-lending-info (token-id uint))
    (ok (map-get? nft-lendings token-id)))

(define-public (burn-design-nft (token-id uint))
    (let ((metadata (unwrap! (map-get? design-metadata token-id) (err u404)))
          (creator (get creator metadata)))
        (asserts! (is-eq tx-sender creator) err-owner-only)
        (try! (nft-burn? design-nft token-id tx-sender))
        (map-delete design-metadata token-id)
        (map-delete royalty-splits token-id)
        (map-delete design-licenses token-id)
        (map-delete marketplace-listings token-id)
        (map-delete design-auctions token-id)
        (map-delete nft-lendings token-id)
        (ok true)))
