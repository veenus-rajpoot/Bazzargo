import LegalPage from '../components/LegalPage'

export default function RefundPolicy() {
  return (
    <LegalPage title="Refund Policy" updated="January 2026">
      <div>
        <h2>1. Cancellations Before Match</h2>
        <p>
          Delivery requests cancelled before a traveler is matched are
          eligible for a full refund of any amount charged.
        </p>
      </div>
      <div>
        <h2>2. Cancellations After Match</h2>
        <p>
          If a request is cancelled after a traveler has been matched but
          before pickup, a partial refund may apply to cover the traveler's
          committed time and route.
        </p>
      </div>
      <div>
        <h2>3. Failed or Undelivered Parcels</h2>
        <p>
          If a parcel is not delivered due to a failure on the traveler's
          side, the requester is eligible for a full refund once the issue
          is confirmed by our support team.
        </p>
      </div>
      <div>
        <h2>4. How Refunds Are Processed</h2>
        <p>
          Approved refunds are issued to the original payment method and
          typically reflect within 5–7 business days, depending on your
          bank or payment provider.
        </p>
      </div>
      <div>
        <h2>5. Requesting a Refund</h2>
        <p>
          To request a refund, contact{' '}
          <a href="mailto:support@bazzargo.com" className="font-semibold text-brand-600">
            support@bazzargo.com
          </a>{' '}
          with your delivery reference and reason for the request.
        </p>
      </div>
    </LegalPage>
  )
}
