# tseretnip

## Configuration

This project uses `dart-define-from-file` for environment variables.

1.  Copy `config.template.json` to `config.json`.
2.  Fill in your Supabase credentials in `config.json`.
3.  Run the app with:
    ```bash
    flutter run --dart-define-from-file=config.json
    ```