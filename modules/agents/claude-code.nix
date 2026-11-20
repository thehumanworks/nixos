{ ... }:
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      env = {
        CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS = "100000";
      };
      advisor = "fable";
      model = "claude-opus-5-5";
      effortLevel = "high";
      autoCompactEnabled = true;
      autoCompactWindow = 400000;
      autoMemoryEnabled = true;
      autoScrollEnabled = true;
      awaySummaryEnabled = true;
      bashEditDiffEnabled = true;
      channelsEnabled = true;
      copyOnSelect = true;
      enableArtifact = true;
      spinnerTipsEnabled = true;
      showThinkingSummaries = true;
      showTurnDuration = true;
      shellcheck = true;
      enableWorkflows = true;
      idleCompaction = true;
      outputStyle = "Concise";
      promptCacheTtl = "1h";
      subagentPromptCacheTtl = "1h";
      terminalProgressBarEnabled = true;
      tui = "fullscreen";
      permissions.defaultMode = "auto";
      theme = "dark";
    };
  };
}
