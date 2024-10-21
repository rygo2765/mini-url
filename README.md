# MiniURL 

MiniURL is a URL shortener built with Ruby on Rails 7.2.1. It allows users to shorten URLs, track clicks, and view detailed usage report on a simple dashboard.

## Prerequisites
Ensure you ahve the following installed before starting: 
1. Docker
2. Visual Studio Code (VSCode)
3. Dev Containers Extension for VSCode

## Installation Guide
1. **Clone the Repository** 
```bash 
git clone git@github.com:rygo2765/mini-url.git
cd miniurl
```

2. **Open in Dev Container**
- Open the project in VSCode
- When prompted, select "Reopen in Container". Alternatively, you can use the Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`), and search for `Dev Containers: Open Folder in Container...`.  This will automatically set up the development environment with all dependencies.

3. **Run the Application:** Once the container is set up, run the following command in the terminal to start the app: 
```bash
bin/dev
```

## Dependencies
Since the project uses a development container, dependencies such as Ruby, Rails, PostgreSQL, TailwindCSS, RSpec are automatically installed inside the container. 

## Testing
To run the both unit and integration test, use the following command in the terminal: 
```bash
bundle exec rspec
```

## Deployed Application 
The live application can be accessed at: [MiniURL - Deployed Application URL](https://miniurl-z5se.onrender.com/)
