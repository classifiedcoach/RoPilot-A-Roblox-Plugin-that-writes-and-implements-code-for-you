# RoCopilot - Roblox Plugin That Codes Your Game For You

## Overview
RoCopilot is a powerful Roblox Studio plugin that leverages AI models to code your game for you. With natural language prompts, you can create new scripts, modify existing ones, and ask questions about your game's codebase. RoCopilot supports multiple AI providers, including OpenAI's GPT-4, Anthropic's Claude, and Google's Gemini, giving you the flexibility to choose the best model for your needs.

## Features
* **AI-Powered Code Generation and Updates**: Use natural language prompts to create new scripts, modify existing code, or get answers about your game's codebase.
* **Multiple AI Provider Support**: Choose from OpenAI GPT-4, Anthropic Claude, or Google Gemini, and input your own API keys.
* **Service Selection**: Customize which services (e.g., Workspace, ServerScriptService, etc.) to include in code updates.
* **Mode Toggle**: Switch between "Code" mode for code changes and "Question" mode to ask questions about your codebase.
* **Undo Changes**: View a history of changes and undo specific changes if needed.
* **User-Friendly Interface**: Simple GUI with dynamic text boxes, settings menu, and loading indicators.
* **Code Preview**: Automatically opens updated scripts in the Roblox Studio script editor for review.
* **Non-Destructive Updates**: Original code is commented out before changes are applied, allowing for easy rollback if needed.

## Usage

### Launch RoCopilot:
1. In Roblox Studio, click on the "RoPilot Coding Agent" button in the Plugins tab to open the RoCopilot interface.

### Select an AI Provider:
1. Click on the "API Provider" button at the top right of the plugin interface.
2. Choose your preferred AI provider from the dropdown menu:
   * OpenAI GPT-4o
   * Anthropic 3.5 Sonnet
   * Google 1.5 Pro
3. Enter your API key for the selected provider in the text box that appears.
4. Click "Use This API Key" to save your API key.

### Configure Settings:
1. Click on the "Settings" button to open the settings menu.
2. Service Selection:
   * Toggle the checkboxes to select which services you want RoCopilot to include in code updates (e.g., Workspace, ServerScriptService).
3. Mode Toggle:
   * Use the toggle button to switch between "Code" mode and "Question" mode.
   * Code Mode: RoCopilot will make code changes based on your prompts.
   * Question Mode: RoCopilot will answer questions about your codebase.

### Enter Your Prompt:
1. In the text box, enter your code update request or question in natural language.
2. Examples:
   * Code Mode: "Create a new script that prints 'Hello' and the current timestamp every 5 seconds."
   * Question Mode: "How many scripts in my game use the DataStore service?"

### Send Prompt:
1. Click the "Send Prompt" button to process your request.
2. A loading indicator will appear while RoCopilot communicates with the AI model.

### Review Results:
1. For Code Changes:
   * The plugin will apply the changes and open the updated scripts for your review.
   * Original code is commented out to allow easy rollback.
2. For Questions:
   * The response will appear in the text box.
   * Check the response area at the bottom of the plugin interface for success or error messages.

### View and Manage Changes:
1. Click the "View Changes" button to see a history of changes made.
2. From the changes view, you can:
   * Goto Change: Navigate directly to the script and line where the change was made.
   * Undo Change: Revert a specific change.
3. Use the "Undo Most Recent Change" button to quickly undo the latest change.

## Configuration

### Before using the plugin, ensure you have API keys for your preferred AI providers:

#### Obtain API Keys:
* OpenAI GPT-4o: [OpenAI API](https://openai.com)
* Anthropic 3.5 Sonnet: [Anthropic API](https://anthropic.com)
* Google 1.5 Pro: [Google Cloud AI Platform](https://cloud.google.com)

#### Input Your API Key into RoCopilot:
* Follow the steps in the Usage section under Select an AI Provider.

## Important Notes
* **Internet Connection**: This plugin requires an active internet connection to communicate with the AI APIs.
* **HTTP Requests**: Ensure you have the necessary permissions to make HTTP requests in your Roblox Studio settings.
* **API Costs**: Be aware of the costs associated with API usage from your chosen provider.
* **Script Selection**: The plugin allows you to select which services to include in code updates via the settings menu.
* **Review Changes**: Always review the changes made by the plugin before publishing your game.

### Limitations:
* The plugin currently focuses on scripts and their contents. It does not modify models, sounds, meshes, etc.
* Undo functionality is provided within the plugin, but it's recommended to back up your work.

## Quick-Start Test Prompts

### Test Prompt 1 (Code Mode):
```
Create a new script for me that prints to the console 'Hello' and the current timestamp once every 5 seconds. Also, create a separate new script that adds a big red GUI button to the screen that makes a different GUI frame open and close when clicked.
```

### Test Prompt 2 (After Test Prompt 1):
```
Change the script that prints 'Hello' and the current timestamp once every 5 seconds to instead print once every second. Also, find the big red GUI button and make it pink.
```

## Backlog Ideas
* Google often returns invalid/unreal Service names (It hallucinates names of services where it wants to store scripts)
  
* Re-Implement the dynamic resizing of the UserRequestInput text box so that we can have very clean and dynamically resized user inputs and API responses.
  
* Ensure we have the "CurrentMode" functionality working such that questions get presented properly in UserRequestInput and Code Changes get implemented into scripts with proper structure.
  
* Use the API provider's new JSON structure response flags/settings, which essentially force the models to response in a JSON structure.

* Saving API provider and API keys across user sessions.

* Proactive suggestions button, where the plugin just submits their experience's contents and receive back a set of "cards" which have plain english suggestions on them, that a user can click on to have them implemented.

* Accessing more elements of the experience, not just the script's contents, such as in-world models and their attributes.

* Allowing the plugin to make changes to the actual world including moving/editing properties of/adding models/sounds/etc...

* Implenting an alterantive approach to saving changes such that users can "Ctrl+Z"/"Ctrl+SHFT+Z" to undo/redo changes implemented by the plugin. (In addition to my changes screen already implemented)

* Enabling users to more granularly select which scripts/assets of the experience to include in AI responses

* Indicate to users the expected # of tokens/associated cost of API prompts before they're sent and give feedback on cost consumed after responses are replied. Dashboard to track across responses?

* Make the error responses from the API even more clear, so users can more quickly understand when they've reached issues such as max input/output token limits or have consumed their full budgets.

* Allow users to connect to their own locally ran AI LLM models, such as a LLama 7B model running on the same laptop as their Roblox Studio instance.

* Embed a model directly within the plugin/access a locally embedded model in Roblox studio from Roblox.

* Add support for the latest models released by major providers, and add support for even more popular models recently released.

* Add an Icon for the plugin so it has a pretty image in the Roblox Studio Plugin selection frame in the top of the screen.

## Disclaimer
This plugin is not officially affiliated with or endorsed by Roblox Corporation, OpenAI, Anthropic, or Google. Use it at your own discretion and always back up your projects before making significant changes.
