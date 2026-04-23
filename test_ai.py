import asyncio
import base64
import os
from browser_use import Agent, Browser
from browser_use.llm import ChatAnthropic

DEFAULT_MODEL = "claude-sonnet-4-6"
DEFAULT_APP_URL = "https://nexus-finance-6c6c6.web.app/"


async def main():
    model = os.environ.get("MODEL", DEFAULT_MODEL)
    app_url = os.environ.get("APP_URL", DEFAULT_APP_URL)

    browser = Browser()
    llm = ChatAnthropic(
        model=model,
        api_key=os.environ.get("ANTHROPIC_API_KEY"),
        temperature=0.0
    )

    agent = Agent(
        browser=browser,
        task=(
            f"As a first-time QA tester, start by signing up for a new account on {app_url}. "
            "Then explore the entire application thoroughly, documenting all user flows, buttons, links, and navigations. "
            "Take screenshots at each major step and describe what you're doing in detail. "
            "Cover all possible interactions as if you're testing the app for the first time."
        ),
        llm=llm
    )

    # 3. Run the agent and capture the history
    history = await agent.run()

    # 4. Process history to generate comprehensive documentation
    markdown_content = "# App Documentation\n\n"
    markdown_content += "This documentation covers the complete user journey through the app, including signup and all major flows.\n\n"

    thoughts = history.model_thoughts()
    actions = history.model_actions()
    urls = history.urls()
    screenshots = history.screenshots()

    for i, (thought, action, url, screenshot_b64) in enumerate(zip(thoughts, actions, urls, screenshots)):
        if screenshot_b64:
            # Create descriptive filename
            action_name = list(action.keys())[0] if action else 'unknown'
            screenshot_filename = f"step_{i+1}_{action_name}.png"
            
            # Save screenshot
            with open(screenshot_filename, "wb") as f:
                f.write(base64.b64decode(screenshot_b64))
            
            # Add section to markdown
            goal = thought.current_state.next_goal if thought and hasattr(thought, 'current_state') else 'Unknown goal'
            markdown_content += f"## Step {i+1}: {goal}\n\n"
            markdown_content += f"**URL:** {url or 'N/A'}\n\n"
            markdown_content += f"**Action:** {action_name}\n\n"
            if action:
                markdown_content += f"**Details:** {action}\n\n"
            markdown_content += f"![Screenshot]({screenshot_filename})\n\n"

    # Save the documentation
    with open("app_documentation.md", "w") as f:
        f.write(markdown_content)
    
    print("Comprehensive documentation generated: app_documentation.md")

if __name__ == "__main__":
    asyncio.run(main())
