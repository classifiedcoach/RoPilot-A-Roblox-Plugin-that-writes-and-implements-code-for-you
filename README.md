# RoCopilot - Roblox Plugin That Codes Your Game For You

## Overview

This plugin allows you to make code changes across multiple scripts in your game with natural language requests, streamlining the development process and enhancing productivity. The RoCopilot - Roblox Coding Agent Plugin is a powerful tool that allows developers to choose their AI model of choice and their own API keys to make natural language requests into new scripts, updated existing scripts, and net new code development. 


## Features

- **AI-Powered Code Updates**: Utilize Anthropic/Google/OpenAI models to interpret and implement code changes based on natural language requests.
- **Multi-Script Support**: Automatically search and update code across ServerScriptService, ReplicatedStorage, and StarterGui.
- **User-Friendly Interface**: A simple GUI for entering update requests and viewing results.
- **Code Preview**: Automatically opens updated scripts in the Roblox Studio script editor for review.
- **Non-Destructive Updates**: Original code is commented out before changes are applied, allowing for easy rollback if needed.

## Installation

1. Download the `ClaudeCodeUpdater.rbxmx` file from the releases section of this repository.
2. In Roblox Studio, go to the "Plugins" tab.
3. Click on "Plugins Folder" to open the plugins directory.
4. Move the downloaded `ClaudeCodeUpdater.rbxmx` file into this directory.
5. Restart Roblox Studio.

## Usage

1. In Roblox Studio, look for the "Code Updater" button in the Plugins tab.
2. Click the button to open the Claude Code Updater interface.
3. In the text box, enter your code update request in natural language.
   Example: "Add a print statement at the start of the 'updateDataStore' function in the onboardingtutorialcontrol script"
4. Click the "Update Code" button to process your request.
5. The plugin will search for the relevant scripts, apply the changes, and open the updated scripts for your review.
6. Check the response area at the bottom of the plugin interface for success or error messages.

## Configuration

Before using the plugin, you need to set up your Claude API key:

1. Open the plugin script in Roblox Studio.
2. Locate the `sendToClaudeAPI` function.
3. Replace the empty string in `local apiKey = ""` with your actual Claude API key.

## Important Notes

- This plugin requires an active internet connection to communicate with the Claude API.
- Ensure you have the necessary permissions to make HTTP requests in your Roblox Studio settings.
- Always review the changes made by the plugin before publishing your game.
- The plugin currently searches for scripts in ServerScriptService, ReplicatedStorage, and StarterGui. Modify the `serializeAllScripts` function if you need to include additional services.


## Disclaimer

This plugin is not officially affiliated with or endorsed by Roblox Corporation or Anthropic. Use it at your own discretion and always backup your projects before making significant changes.
