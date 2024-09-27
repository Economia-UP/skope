import os
import requests
import pandas as pd

FRED_API_KEY = '40c955c0bd974d31dab135e7624bdb20'

def fetch_fred_data():
    # Retrieve the FRED API key from environment variables
    # FRED_API_KEY = os.getenv('FRED_API_KEY')
    SERIES_ID = 'IRLTLT01MXM156N'  # Your FRED series ID
    FRED_URL = f'https://api.stlouisfed.org/fred/series/observations?series_id={SERIES_ID}&api_key={FRED_API_KEY}&file_type=json'

    # Fetch data from the FRED API
    response = requests.get(FRED_URL)
    response.raise_for_status()  # Raise an error if the response status is not 200
    data = response.json()

    # Extract observations data
    observations = data.get('observations', [])
    if not observations:
        raise ValueError(f"No observations found for series ID {SERIES_ID}")

    # Create a DataFrame from the observations
    df = pd.DataFrame(observations)
    df['date'] = pd.to_datetime(df['date'])
    df['value'] = pd.to_numeric(df['value'], errors='coerce')

    # Define the output directory and ensure it exists
    output_dir = 'US/Monitor cambiario'
    os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'fred_data.csv')

    # Save the DataFrame to a CSV file in the specified folder
    df.to_csv(output_file, index=False)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    fetch_fred_data()
