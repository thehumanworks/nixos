{ ... }:
{
  programs.pi-coding-agent = {
    enable = true;
    mutableSettings = false;
    settings = {
      # model settings
      defaultModel = "gpt-6.2-astra";
      defaultProvider = "openai";
      enabledModels = [
        "openai/gpt-6.2-astra"
        "openai/gpt-6.2-sol"
      ];
      defaultThinkingLevel = "max";

      # context management settings
      compaction.enabled = true;
      cacheWarming = "idle";
      transport = "websocket-cached";

      # TUI settings
      tuiMode = "fullscreen";
      fullscreenScrollbar = "hidden";
      fullscreenCopyOnSelect = true;
      terminal.showTerminalProgress = true;
      codemode.mode = "only";

      enableInstallTelemetry = false;
      quietStartup = true;
      collapseChangelog = true;
      showCacheMissNotices = true;
      defaultProjectTrust = "always";
      hideThinkingBlock = true;

      # extensions
      packages = [
        "npm:pi-open-tui"
        "npm:@nothumanwork/pi-fast"
        "npm:@nothumanwork/pi-advisor"
        "npm:@nothumanwork/pi-background-compaction"
        "npm:@nothumanwork/pi-idle-compaction"
      ];

      # extension settings
      advisorModel = "openai/gpt-6.2-astra";

      backgroundCompaction = {
        enabled = true;
        model = "openai/gpt-6.2-sol";
      };

      idleCompaction = {
        enabled = true;
        tokenThreshold = 150000;
        idleMinutes = 5;
      };

      fast = {
        ultrafastModels = [
          "gpt-6.2-astra"
          "gpt-6.2-sol"
        ];
      };
    };
  };

  # MCP Servers
  home.file.".pi/agent/mcp.json".text = builtins.toJSON {
    mcpServers = {
      exa = {
        url = "https://mcp.exa.ai/mcp";
        description = "Web search tooling with Exa as the web search provider";
        headers.Authorization = "Bearer \${EXA_API_KEY}";
      };
    };
  };

  # OpenTUI
  home.file.".pi/agent/open-tui.json".text = builtins.toJSON {
    enabled = true;
    header = true;
    inlineFooter = false;
    copyButtons = true;
    settingsLanguage = "en";
    cursorStyle = "block";
    icons.mode = "auto";
    footerSegments = {
      cwd = true;
      hostname = false;
      sessionName = false;
      gitBranch = true;
      gitStatus = true;
      gitCommit = false;
      runtime = true;
      context = true;
      contextBar = true;
      tokens = true;
      cost = true;
      liveTps = true;
      extensionSegments = true;
      extensionStatuses = true;
      capitalizeProviderName = true;
      nerdIconSpacing = false;
    };
    telemetry = {
      enabled = false;
      tps = true;
      ttft = true;
      duration = true;
      tokens = true;
      stalls = true;
      cost = true;
    };
    thinkingPeek.lines = 2;
    toolView = {
      mode = "compact";
      extensionTools = true;
      exclude = [];
    };
  };
}
