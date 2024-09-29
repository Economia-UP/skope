# Skope

This project automates the fetching, processing, and updating of data from APIs such as FRED and INEGI, saving the results as CSV files in the repository. The workflow is managed through GitHub Actions to ensure data is updated regularly.

## Table of Contents
1. [Project Structure](#project-structure)
2. [Prerequisites](#prerequisites)
3. [Adding and Editing Python Scripts](#adding-and-editing-python-scripts)
4. [Editing the GitHub Actions Workflow (YAML File)](#editing-the-github-actions-workflow-yaml-file)
5. [Managing Access Tokens and Secrets](#managing-access-tokens-and-secrets)
6. [Common Issues and Troubleshooting](#common-issues-and-troubleshooting)

## Project Structure

Here's a quick overview of the main folders and files you will interact with:

```
├── .github
│   └── workflows
│       └── update_data.yml       # The GitHub Actions workflow file
├── US
│   └── Monitor cambiario
│       ├── *.py    # Example Python script to fetch data
│       └── *.csv   # Output CSV file updated by the script
├── MX
│   └── Monitor cambiario
│       ├── *.py    # Example Python script to fetch data
│       └── *.csv   # Output CSV file updated by the script
|
└── README.md                     # Documentation file
```

## Prerequisites

- **GitHub account** with appropriate permissions to push changes to the repository.
- **Python 3.x** installed locally for script testing and debugging.
- **Git** installed to clone the repository and manage version control.

## Adding and Editing Python Scripts

### 1. Writing Python Scripts

- Python scripts should fetch, process, and save data to CSV files. Use libraries like `requests`, `pandas`, and `os` to interact with APIs and handle file operations.
- Ensure each script has a clear purpose and error handling to manage failed API requests or data processing issues.
- Save the output CSV files in the appropriate directory based on the data type (e.g., `US/Monitor cambiario` for US data).

**Example Template for Python Scripts:**

```python
import os
import requests
import pandas as pd

def fetch_data():
    # Example API request
    response = requests.get('API_URL_HERE')
    response.raise_for_status()  # Raise error if request fails
    data = response.json()

    # Process data into a DataFrame
    df = pd.DataFrame(data['observations'])
    
    # Save DataFrame as CSV
    output_dir = 'PATH/TO/DIRECTORY'
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, 'output_file.csv')
    df.to_csv(output_file, index=False)
    print(f"Data saved to {output_file}")

if __name__ == "__main__":
    fetch_data()
```

### 2. Where to Put Python Scripts

- Place new Python scripts inside the relevant directory (e.g., `US/Monitor cambiario` or `MX`) based on the data's geographic region or topic.
- Ensure the script’s file name reflects its function, like `fetch_fred_data.py` for fetching FRED data.

## Editing the GitHub Actions Workflow (YAML File)

The GitHub Actions workflow, typically located in `.github/workflows/update_data.yml`, automates the data fetching and updating process.

### 1. Editing the YAML File

To add a new Python script to the workflow, follow these steps:

1. Open `.github/workflows/update_data.yml`.
2. Add a new step under the `jobs` section for the Python script you want to run.

**Example Step:**

```yaml
      - name: Fetch New Data
        env:
          API_KEY: ${{ secrets.API_KEY }}
        run: |
          python 'US/Monitor cambiario/your_script.py'
```

3. Make sure the script paths and any required environment variables (e.g., API keys) are correctly set up.

### 2. Adjusting the Schedule

- The schedule for the job is set in the `on` section using cron syntax.
- Example: To run every 5 minutes, adjust the cron line to:
  ```yaml
  schedule:
    - cron: '*/5 * * * *'
  ```

## Managing Access Tokens and Secrets

### 1. Adding or Changing Access Tokens

Access tokens or API keys are stored as GitHub Secrets for security. To manage secrets:

1. Go to your GitHub repository.
2. Navigate to **Settings > Secrets and variables > Actions**.
3. Click **New repository secret**.
4. Enter the name (e.g., `FRED_API_KEY`) and value of the secret.

### 2. Using Secrets in Python Scripts

- Retrieve secrets in your Python scripts using environment variables:

  ```python
  import os
  API_KEY = os.getenv('FRED_API_KEY')
  ```

- Make sure the secret names in your workflow YAML file match those you set up in GitHub.

## Common Issues and Troubleshooting

- **403 Errors (Permission Denied):** Ensure your GitHub token has the correct permissions.
- **API Rate Limits:** Monitor API usage and consider caching data locally if rate limits are exceeded.
- **Script Errors:** Check logs from GitHub Actions to debug issues. Logs provide detailed feedback on each step's execution.
