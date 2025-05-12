;; Entity Verification Contract
;; Validates and stores information about regulated businesses

(define-data-var admin principal tx-sender)

;; Entity data structure
(define-map entities
  { entity-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    jurisdiction: (string-ascii 50),
    registration-number: (string-ascii 50),
    verification-status: (string-ascii 20),
    verification-date: uint,
    verified-by: principal
  }
)

;; Public function to register a new entity
(define-public (register-entity (entity-id (string-ascii 64))
                               (name (string-ascii 100))
                               (jurisdiction (string-ascii 50))
                               (registration-number (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? entities { entity-id: entity-id })) (err u100))

    (map-set entities
      { entity-id: entity-id }
      {
        name: name,
        jurisdiction: jurisdiction,
        registration-number: registration-number,
        verification-status: "pending",
        verification-date: u0,
        verified-by: tx-sender
      }
    )
    (ok true)
  )
)

;; Public function to verify an entity
(define-public (verify-entity (entity-id (string-ascii 64)) (status (string-ascii 20)))
  (let ((entity (unwrap! (map-get? entities { entity-id: entity-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set entities
        { entity-id: entity-id }
        (merge entity {
          verification-status: status,
          verification-date: block-height,
          verified-by: tx-sender
        })
      )
      (ok true)
    )
  )
)

;; Read-only function to get entity details
(define-read-only (get-entity (entity-id (string-ascii 64)))
  (map-get? entities { entity-id: entity-id })
)

;; Function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
