# Skope

This project automates the fetching, processing, and updating of data from APIs such as FRED and INEGI, saving the results as CSV files in the repository. The workflow is managed through GitHub Actions to ensure data is updated regularly.

## Table of Contents
1. [Project Structure](#project-structure)
2. [Prerequisites](#prerequisites)
3. [Adding and Editing R Scripts](#adding-and-editing-r-scripts)
4. [Editing the GitHub Actions Workflow (YAML File)](#editing-the-github-actions-workflow-yaml-file)
5. [Managing Access Tokens and Secrets](#managing-access-tokens-and-secrets)
6. [Common Issues and Troubleshooting](#common-issues-and-troubleshooting)

## Project Structure

Here's a quick overview of the main folders and files in this layout, including workflows, data, tests, and reference materials:

```
├── .github/workflows/     # CI workflows
├── r/                    # Data-fetching R scripts
├── data/                 # Generated CSVs
├── plots/                # Output graphics
├── tests/                # testthat suite
├── pdf/                  # Reference PDFs
├── calendar/             # Calendar PDFs
├── environment.yml       # Conda environment
└── README.md
```

## Prerequisites

- **GitHub account** with appropriate permissions to push changes to the repository.
- **R** installed locally for script testing and debugging.
- **Git** installed to clone the repository and manage version control.

## Adding and Editing R Scripts

### 1. Writing R Scripts

- **R scripts** should fetch, process, and save data to CSV files. Use libraries like `httr`, `jsonlite`, `dplyr`, and `readr` to interact with APIs, process the data, and handle file operations.
- Ensure each script has a clear purpose and error handling to manage failed API requests or data processing issues.
- Save the output CSV files in the appropriate directory based on the data type (e.g., `US/Monitor cambiario` for US data).

**Example Template for R Scripts:**

### 2. Where to Put R Scripts

- Place new R scripts inside the relevant directory (e.g., `r`) based on the data's geographic region or topic.
- Ensure the script’s file name reflects its function, like `inflation_data.r` for fetching inflation data.

## Editing the GitHub Actions Workflow (YAML File)

The GitHub Actions workflow, typically located in `.github/workflows/update_data.yml`, automates the data fetching and updating process.

### 1. Editing the YAML File

To add a new R script to the workflow, follow these steps:

1. Open `.github/workflows/update_data.yml`.
2. Add a new step under the `jobs` section for the R script you want to run.
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

### 2. Using Secrets in R Scripts

- Retrieve secrets in your R scripts using environment variables:

  ```r
  api_key <- Sys.getenv('FRED_API_KEY')
  ```

- Make sure the secret names in your workflow YAML file match those you set up in GitHub.

## Common Issues and Troubleshooting

- **403 Errors (Permission Denied):** Ensure your GitHub token has the correct permissions.
- **API Rate Limits:** Monitor API usage and consider caching data locally if rate limits are exceeded.
- **Script Errors:** Check logs from GitHub Actions to debug issues. Logs provide detailed feedback on each step's execution.
  
---

### Key Changes:

- **Replaced Python with R** in the script-writing section. The R scripts use libraries like `httr`, `jsonlite`, `dplyr`, and `readr` for API interactions and data processing.
- The workflow and secrets management sections are largely unchanged but adapted for R, with `Sys.getenv()` for environment variables.
- R-specific libraries and functions are used for fetching and processing data.

This setup ensures your R scripts are correctly integrated with GitHub Actions and can automate the process of fetching and updating your data regularly.
