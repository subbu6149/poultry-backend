# Poultry Farm Manager - Backend

Node.js + Express + TypeScript backend for the Farm Manager application.

## Features

- **Authentication**: Phone-based login with JWT tokens
- **User Management**: CRUD operations with role-based access control
- **Role-Based Permissions**: VIEW and EDIT permissions across modules
- **Complaints System**: Employee complaint submission and tracking
- **MySQL Database**: Comprehensive schema with 61 tables

## Tech Stack

- Node.js
- Express.js
- TypeScript
- MySQL
- JWT Authentication
- bcrypt for password hashing

## Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables:
```bash
cp .env.example .env
```

Edit `.env` with your database credentials:
```
PORT=5000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=farm_manager
JWT_SECRET=your-secret-key
CORS_ORIGIN=http://localhost:3000
```

3. Create database and run schema:
- Start XAMPP MySQL server
- Create database: `farm_manager`
- Import schema from `database/schema.sql`

4. Start development server:
```bash
npm run dev
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login with phone and password
- `POST /api/auth/logout` - Logout user

### Users
- `GET /api/users` - Get all users (Super Admin only)
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user
- `GET /api/users/:id/permissions` - Get user permissions

### Roles
- `GET /api/roles` - Get all roles

### Complaints
- `GET /api/complaints` - Get complaints (filtered by user)
- `POST /api/complaints` - Create complaint
- `PUT /api/complaints/:id` - Update complaint
- `DELETE /api/complaints/:id` - Delete complaint

## Project Structure

```
backend/
├── src/
│   ├── config/          # Database configuration
│   ├── controllers/     # Route controllers
│   ├── middleware/      # Auth & permission middleware
│   ├── routes/          # API routes
│   └── server.ts        # Entry point
├── database/            # SQL schema files
├── scripts/             # Utility scripts
└── logs/               # Application logs
```

## Default Users

- **Super Admin**: Phone: `9999`, Password: `9999`
- **Employee**: Phone: `1234`, Password: `1234`

## License

MIT
