;; Requirement Tracking Contract
;; Records applicable regulations for entities

(define-data-var admin principal tx-sender)

;; Requirement data structure
(define-map requirements
  { requirement-id: (string-ascii 64) }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    regulation-ref: (string-ascii 100),
    jurisdiction: (string-ascii 50),
    created-at: uint,
    created-by: principal
  }
)

;; Entity-Requirement mapping
(define-map entity-requirements
  { entity-id: (string-ascii 64), requirement-id: (string-ascii 64) }
  {
    applicable: bool,
    due-date: uint,
    status: (string-ascii 20)
  }
)

;; Public function to add a new requirement
(define-public (add-requirement (requirement-id (string-ascii 64))
                               (title (string-ascii 100))
                               (description (string-ascii 500))
                               (regulation-ref (string-ascii 100))
                               (jurisdiction (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? requirements { requirement-id: requirement-id })) (err u100))

    (map-set requirements
      { requirement-id: requirement-id }
      {
        title: title,
        description: description,
        regulation-ref: regulation-ref,
        jurisdiction: jurisdiction,
        created-at: block-height,
        created-by: tx-sender
      }
    )
    (ok true)
  )
)

;; Public function to assign requirement to entity
(define-public (assign-requirement (entity-id (string-ascii 64))
                                  (requirement-id (string-ascii 64))
                                  (due-date uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? requirements { requirement-id: requirement-id })) (err u404))

    (map-set entity-requirements
      { entity-id: entity-id, requirement-id: requirement-id }
      {
        applicable: true,
        due-date: due-date,
        status: "assigned"
      }
    )
    (ok true)
  )
)

;; Public function to update requirement status
(define-public (update-requirement-status (entity-id (string-ascii 64))
                                         (requirement-id (string-ascii 64))
                                         (status (string-ascii 20)))
  (let ((req-mapping (unwrap! (map-get? entity-requirements { entity-id: entity-id, requirement-id: requirement-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set entity-requirements
        { entity-id: entity-id, requirement-id: requirement-id }
        (merge req-mapping { status: status })
      )
      (ok true)
    )
  )
)

;; Read-only function to get requirement details
(define-read-only (get-requirement (requirement-id (string-ascii 64)))
  (map-get? requirements { requirement-id: requirement-id })
)

;; Read-only function to get entity requirement mapping
(define-read-only (get-entity-requirement (entity-id (string-ascii 64)) (requirement-id (string-ascii 64)))
  (map-get? entity-requirements { entity-id: entity-id, requirement-id: requirement-id })
)

;; Function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
