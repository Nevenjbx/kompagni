# Create directories
New-Item -ItemType Directory -Force -Path lib\features\auth\screens
New-Item -ItemType Directory -Force -Path lib\features\auth\services
New-Item -ItemType Directory -Force -Path lib\features\client\screens
New-Item -ItemType Directory -Force -Path lib\features\client\services
New-Item -ItemType Directory -Force -Path lib\features\provider\screens
New-Item -ItemType Directory -Force -Path lib\features\provider\services
New-Item -ItemType Directory -Force -Path lib\shared\models
New-Item -ItemType Directory -Force -Path lib\shared\services

# Move Auth Files
Move-Item lib\screens\login_screen.dart lib\features\auth\screens\ -ErrorAction SilentlyContinue
Move-Item lib\screens\signup_screen.dart lib\features\auth\screens\ -ErrorAction SilentlyContinue
Move-Item lib\services\auth_service.dart lib\features\auth\services\ -ErrorAction SilentlyContinue

# Move Client Files
Move-Item lib\screens\home_client.dart lib\features\client\screens\ -ErrorAction SilentlyContinue
Move-Item lib\screens\my_appointments_screen.dart lib\features\client\screens\ -ErrorAction SilentlyContinue
Move-Item lib\screens\provider_details_screen.dart lib\features\client\screens\ -ErrorAction SilentlyContinue
Move-Item lib\screens\provider_list_screen.dart lib\features\client\screens\ -ErrorAction SilentlyContinue
Move-Item lib\services\appointment_service.dart lib\features\client\services\ -ErrorAction SilentlyContinue

# Move Provider Files
Move-Item lib\screens\add_service_screen.dart lib\features\provider\screens\ -ErrorAction SilentlyContinue
Move-Item lib\screens\manage_availability_screen.dart lib\features\provider\screens\ -ErrorAction SilentlyContinue
Move-Item lib\screens\provider_dashboard_screen.dart lib\features\provider\screens\ -ErrorAction SilentlyContinue
Move-Item lib\services\provider_service.dart lib\features\provider\services\ -ErrorAction SilentlyContinue
Move-Item lib\services\service_service.dart lib\features\provider\services\ -ErrorAction SilentlyContinue

# Move Shared Files
Move-Item lib\models\provider.dart lib\shared\models\ -ErrorAction SilentlyContinue
Move-Item lib\models\service.dart lib\shared\models\ -ErrorAction SilentlyContinue
Move-Item lib\models\working_hours.dart lib\shared\models\ -ErrorAction SilentlyContinue
Move-Item lib\services\user_service.dart lib\shared\services\ -ErrorAction SilentlyContinue

Write-Host "Refactoring steps completed."
