import LegalPage from '../components/LegalPage'

export default function Terms() {
  return (
    <LegalPage title="Terms & Conditions" updated="January 2026">
      <div>
        <h2>1. Acceptance of Terms</h2>
        <p>
          By creating a BazzarGo account or using our platform, you agree to
          be bound by these Terms & Conditions and our Privacy Policy.
        </p>
      </div>
      <div>
        <h2>2. Eligibility & KYC</h2>
        <p>
          You must be at least 18 years old and complete identity
          verification (KYC) before posting a delivery request or accepting
          one as a traveler.
        </p>
      </div>
      <div>
        <h2>3. Requester & Traveler Responsibilities</h2>
        <ul>
          <li>Requesters must accurately describe the parcel and its contents.</li>
          <li>Travelers must confirm pickup and drop-off using OTP verification.</li>
          <li>Prohibited, illegal, or hazardous items may never be shipped through BazzarGo.</li>
        </ul>
      </div>
      <div>
        <h2>4. Payments</h2>
        <p>
          Payments are processed securely and released to travelers once
          delivery is confirmed with OTP at drop-off, in line with our
          Refund Policy.
        </p>
      </div>
      <div>
        <h2>5. Account Suspension</h2>
        <p>
          BazzarGo may suspend or terminate accounts that violate these
          terms, engage in fraudulent activity, or compromise the safety of
          the community.
        </p>
      </div>
      <div>
        <h2>6. Limitation of Liability</h2>
        <p>
          BazzarGo facilitates connections between requesters and travelers
          but is not a courier company. Liability for lost or damaged
          parcels is limited as described in our in-app terms at the time of
          each delivery request.
        </p>
      </div>
      <div>
        <h2>7. Contact</h2>
        <p>
          Questions about these terms can be sent to{' '}
          <a href="mailto:support@bazzargo.com" className="font-semibold text-brand-600">
            support@bazzargo.com
          </a>
          .
        </p>
      </div>
    </LegalPage>
  )
}
