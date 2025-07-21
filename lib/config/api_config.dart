class ApiConfig {
  // ============================================================================
  // 🔑 API CONFIGURATION - REQUIRED FOR APP TO WORK
  // ============================================================================

  // 📝 HOW TO GET YOUR OPENAI API KEY:
  // 1. Go to https://platform.openai.com/
  // 2. Create an account or login
  // 3. Navigate to "API keys" section
  // 4. Click "Create new secret key"
  // 5. Copy the key and paste it below

  // IMPORTANT: Replace "YOUR_OPENAI_API_KEY_HERE" with your actual API key
  static const String openAiApiKey = "YOUR_OPENAI_API_KEY_HERE";

  // ============================================================================
  // OPENAI SETTINGS - CUSTOMIZE AS NEEDED
  // ============================================================================

  // Model to use (gpt-3.5-turbo is recommended for cost-effectiveness)
  static const String openAiModel = "gpt-3.5-turbo";

  // Maximum tokens per request (higher = longer responses but more expensive)
  static const int maxTokens = 1000;

  // Temperature (0.0 = more focused, 1.0 = more creative)
  static const double temperature = 0.7;

  // System message to set AI behavior
  static const String systemMessage = """
You are a helpful AI tutor assistant. You help students learn various subjects by:
- Explaining concepts clearly and simply
- Providing examples and analogies
- Breaking down complex topics into manageable parts
- Encouraging students and being patient
- Asking follow-up questions to ensure understanding

Keep responses concise but informative. Always be supportive and encouraging.
""";

  // ============================================================================
  // 🌐 API ENDPOINTS - DON'T CHANGE UNLESS YOU KNOW WHAT YOU'RE DOING
  // ============================================================================

  static const String openAiBaseUrl = "https://api.openai.com/v1";
  static const String chatCompletionsEndpoint = "/chat/completions";

  // ============================================================================
  // ⚙️ REQUEST SETTINGS
  // ============================================================================

  // Timeout for API requests
  static const Duration requestTimeout = Duration(seconds: 30);

  // Maximum retries for failed requests
  static const int maxRetries = 3;

  // Delay between retries
  static const Duration retryDelay = Duration(seconds: 2);

  // ============================================================================
  // 🔒 VALIDATION
  // ============================================================================

  // Check if API key is configured
  static bool get isApiKeyConfigured {
    return openAiApiKey.isNotEmpty &&
        openAiApiKey != "YOUR_OPENAI_API_KEY_HERE" &&
        (openAiApiKey.startsWith("sk-") || openAiApiKey.startsWith("sk-proj-"));
  }

  // Get validation message
  static String get validationMessage {
    if (openAiApiKey.isEmpty || openAiApiKey == "YOUR_OPENAI_API_KEY_HERE") {
      return "Please add your OpenAI API key in lib/config/api_config.dart";
    }
    if (!openAiApiKey.startsWith("sk-") &&
        !openAiApiKey.startsWith("sk-proj-")) {
      return "Invalid OpenAI API key format. Keys should start with 'sk-' or 'sk-proj-'";
    }
    return "API key is configured correctly";
  }
}

// ============================================================================
// 📋 QUICK SETUP CHECKLIST
// ============================================================================
/*

✅ STEP 1: GET YOUR API KEY
   - Visit: https://platform.openai.com/
   - Create account and navigate to API keys
   - Create new secret key

✅ STEP 2: ADD YOUR API KEY
   - Replace "YOUR_OPENAI_API_KEY_HERE" above with your actual key
   - Make sure it starts with "sk-" or "sk-proj-"

✅ STEP 3: TEST THE APP
   - Run the app: flutter run
   - Try asking the AI tutor a question
   - Check if responses are working

✅ STEP 4: CUSTOMIZE (OPTIONAL)
   - Adjust maxTokens for longer/shorter responses
   - Change temperature for more/less creativity
   - Modify systemMessage for different AI behavior

📝 NOTES:
   - Keep your API key secure and don't share it
   - Monitor your usage at https://platform.openai.com/usage
   - Consider setting usage limits to control costs

*/