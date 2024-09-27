import os
import requests
import pandas as pd

def fetch_fred_data():
    FRED_API_KEY = os.getenv('FRED_API_KEY')
    SERIES_ID = 'IRLTLT01MXM156N'  # Replace with your desired FRED series ID
    FRED_URL = f'https://api.stlouisfed.org/fred/series/observations?series_id={SERIES_ID}&api_key={FRED_API_KEY}&file_type=json'

    response = requests.get(FRED_URL)
    response.raise_for_status()  # Raise an error for bad status codes
    data = response.json()

    observations = data.get('observations', [])
    if not observations:
        raise ValueError(f"No observations found for series ID {SERIES_ID}")

    df = pd.DataFrame(observations)
    # Optionally, process the data (e.g., convert dates, handle missing values)
    df['date'] = pd.to_datetime(df['date'])
    df['value'] = pd.to_numeric(df['value'], errors='coerce')

    output_file = 'fred_data.csv'
    df.to_csv(output_file, index=False)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    fetch_fred_data()
