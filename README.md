# Campaign Dispatcher

A proof-of-concept Rails application for automating customer feedback collection. The application simulates sending review requests to a list of customers and tracks their status in real-time using Hotwire (Turbo Streams and Turbo Frames).

## Tech Stack

- **Ruby on Rails 7.2**
- **PostgreSQL** - Database
- **Hotwire (Turbo & Stimulus)** - Real-time UI updates
- **Sidekiq + Redis** - Background job processing
- **Tailwind CSS** - Styling
- **RSpec** - Testing framework

## Prerequisites

- Ruby 3.2.3 or higher
- PostgreSQL
- Redis
- Bundler

## Setup Instructions

### 1. Install Dependencies

```bash
bundle install
```

### 2. Database Setup

```bash
rails db:create
rails db:migrate
```

### 3. Start Redis

Make sure Redis is running on your system:

```bash
# macOS (using Homebrew)
brew services start redis

# Linux
sudo systemctl start redis

# Or run directly
redis-server
```

### 4. Start Sidekiq

In a separate terminal window:

```bash
bundle exec sidekiq
```

### 5. Start the Rails Server

```bash
rails server
```

Or use the provided Procfile.dev to start everything at once:

```bash
bin/dev
```

The application will be available at `http://localhost:3000`

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/requests/campaigns_spec.rb
bundle exec rspec spec/jobs/dispatch_campaign_job_spec.rb
bundle exec rspec spec/system/campaigns_spec.rb
```

## Usage

1. **Create a Campaign**: Click "New Campaign" and enter a title and list of recipients (one per line, format: `Name, Email or Phone`)

2. **View Campaign**: After creation, you'll be redirected to the campaign show page where you can see all recipients

3. **Start Dispatch**: Click "Start Dispatch" to begin processing recipients. The status will update in real-time without page refresh

4. **Monitor Progress**: Watch as recipients change from "Queued" to "Sent" status, and the progress bar updates automatically

## Architecture Decisions

### Data Modeling

- **Campaigns**: Store campaign metadata with status tracking (pending, processing, completed)
- **Recipients**: Belong to campaigns with individual status tracking (queued, sent, failed)
- Status fields use string enums for simplicity and flexibility
- Indexes on recipient status for efficient querying during job processing

### Background Processing

- **Sidekiq** chosen for its reliability and Redis-backed queue
- **DispatchCampaignJob** processes recipients sequentially with simulated delays (1-3 seconds)
- Each recipient update triggers a Turbo Stream broadcast for real-time UI updates
- Campaign progress is broadcast after each recipient update to keep the UI in sync

### Real-time Updates (Hotwire)

- **Turbo Streams**: Used to broadcast individual recipient status updates as they're processed
- **Turbo Frames**: Used for the campaign progress section to enable targeted updates without full page refresh
- Stream subscriptions are scoped per campaign to avoid unnecessary updates
- Broadcasts happen synchronously after database updates to ensure consistency

### Error Handling

- Recipient processing errors are caught and logged, with recipients marked as "failed"
- Campaign status updates to "completed" even if some recipients fail
- Job failures don't crash the entire dispatch process

### UI/UX

- **Tailwind CSS** for modern, responsive styling
- Clean dashboard with status badges and progress indicators
- Real-time updates provide immediate feedback without manual refresh
- Simple recipient input format (text area) for quick data entry

## Future Improvements

Given 40 hours instead of 6, here's what I would add or improve:

### 1. Enhanced Error Handling & Retry Logic
- Implement exponential backoff for failed recipients
- Add retry mechanism with configurable attempts
- Better error categorization (network errors vs validation errors)
- Dead letter queue for permanently failed recipients

### 2. Performance Optimizations
- Batch processing of recipients instead of sequential
- Database query optimization with proper eager loading
- Caching of campaign statistics
- Background job prioritization and queue management

### 3. User Experience Enhancements
- CSV/Excel file upload for bulk recipient import
- Recipient validation before campaign creation
- Campaign scheduling (send at specific time)
- Email/SMS templates with personalization
- Campaign analytics dashboard with charts

### 4. Testing Improvements
- More comprehensive system tests with Turbo Stream assertions
- Integration tests for the full dispatch flow
- Performance tests for large campaigns (1000+ recipients)
- Test coverage for edge cases and error scenarios

### 5. Production Readiness
- Authentication and authorization (Devise + Pundit)
- Rate limiting for API endpoints
- Monitoring and alerting (Sentry, DataDog)
- Background job monitoring (Sidekiq Web UI)
- Database connection pooling optimization
- Proper logging and structured error reporting

### 6. Feature Additions
- Campaign templates for reusable recipient lists
- Recipient segmentation and filtering
- Campaign scheduling and recurring campaigns
- Integration with real email/SMS providers (SendGrid, Twilio)
- Webhook support for external integrations

### 7. Code Quality
- Service objects for complex business logic extraction
- Form objects for campaign creation validation
- Background job idempotency
- Database transaction management improvements
- API versioning if exposing endpoints


## License

This is a technical assessment project.
