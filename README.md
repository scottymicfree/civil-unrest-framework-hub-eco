# Lucy's FiveM Modding

Welcome to Lucy's FiveM Modding hub! This project is a standalone web application designed to help you create, manage, analyze, and upgrade FiveM Lua scripts using an AI-assisted IDE environment.

## Features

- **A.I. Coding Station (IDE):** A live IDE embedded in your browser with real-time feedback. Includes an output terminal, a mock variable simulator, and interactive state debugging.
- **Full Resource Import:** Drag and drop full FiveM resource folders directly into the Explorer. Lucy will analyze the entire file structure and provide automated upgrade or debugging suggestions for all your Lua files.
- **Interactive Debugger:** Test your generated scripts line-by-line. Provide mock application state variables and watch how Lucy dynamically predicts script behavior.
- **Auto-Fixes:** Let Lucy automatically apply performance, security, and feature quality upgrades to your scripts with a single click.
- **Modding Toolbelt:** Quick access to FiveM Docs, GTA5-Mods, Discord, and a seamless path to export and publish your scripts to GitHub.

## Getting Started

1. Double-click the `start.bat` file to automatically install the required Node.js dependencies and start the development server.
2. The application will start and be accessible at `http://localhost:3000`.
3. Open the side menu (gear icon) in the bottom-left to configure your **Gemini API Key**.
4. Use the bottom panel to trigger **A.I. Code Generation** or access the **Coding Station**.

## Usage

- **Generating a Script:** Click the prompt input bar along the bottom panel, type your request (e.g., "Create a vehicle spawner"), and Lucy will generate the code.
- **Reviewing & Exploring:** When code is generated, the Coding Station IDE will open. You can edit the `script.lua` manually, or use tools to "Run / Test".
- **Analyzing a Workspace:** Drag and drop a folder from your PC onto the workspace window. Lucy will parse everything and offer structural analysis.

## Technologies Used

- **Frontend:** React 18, Vite, Tailwind CSS, PrismJS syntax highlighter.
- **Backend:** Express.js proxy.
- **AI Core:** Google GenAI SDK (powered by `gemini-2.5-flash`).

Enjoy modding creatively!
