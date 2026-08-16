import LegalPage from '../components/LegalPage'

export default function PrivacyPolicy() {
  return (
    <LegalPage title="Privacy Policy" updated="January 2026">
      <div>
        <h2>1. Information We Collect</h2>
        <p>
          To provide route matching, OTP verification, and KYC compliance, we
          collect information such as your name, contact details, government
          ID for identity verification, delivery addresses, trip details, and
          payment information.
        </p>
      </div>
      <div>
        <h2>2. How We Use Your Information</h2>
        <p>
          We use your information to match delivery requests with travelers,
          verify identities, process payments, communicate updates about
          your delivery, and keep the BazzarGo community safe.
        </p>
      </div>
      <div>
        <h2>3. Sharing of Information</h2>
        <p>
          We share only the information necessary for a delivery to happen —
          such as pickup and drop-off details between a matched requester and
          traveler. We do not sell your personal data to third parties.
        </p>
      </div>
      <div>
        <h2>4. Data Security</h2>
        <p>
          KYC records, payment details, and account credentials are stored
          using encryption in transit and at rest, with access limited to
          systems and staff that need it to operate the platform.
        </p>
      </div>
      <div>
        <h2>5. Your Rights</h2>
        <ul>
          <li>Request a copy of the data we hold about you.</li>
          <li>Correct inaccurate account information.</li>
          <li>
            Request permanent deletion of your account via our{' '}
            <a href="/delete-account" className="font-semibold text-brand-600">
              Delete Account
            </a>{' '}
            page.
          </li>
        </ul>
      </div>
      <div>
        <h2>6. Contact Us</h2>
        <p>
          Questions about this policy can be sent to{' '}
          <a href="mailto:support@bazzargo.com" className="font-semibold text-brand-600">
            support@bazzargo.com
          </a>
          .
        </p>
      </div>
    </LegalPage>
  )
}
