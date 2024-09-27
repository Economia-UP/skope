import os
import requests
import pandas as pd

# INEGI_API_KEY = '446548c3-7b55-4b22-8430-ac8f251ea555'

def inflation():
    # Retrieve the INEGI API key from environment variables
    INEGI_API_KEY = os.getenv('INEGI_API_KEY')
    SERIES_ID = '910406'  # Your FRED series ID
    INEGI_URL = f'https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/{SERIES_ID}/es/0700/false/BIE/2.0/{INEGI_API_KEY}?type=json'

    # Fetch data from the INEGI API
    response = requests.get(INEGI_URL)
    response.raise_for_status()  # Raise an error if the response status is not 200
    data = response.json()

    # Extract observations data
    observations = data.get('Series', {})[0].get('OBSERVATIONS', [])
    if not observations:
        raise ValueError(f"No observations found for series ID {SERIES_ID}")

    # Create a DataFrame from the observations
    df = pd.DataFrame(observations)
    df = df[['TIME_PERIOD', 'OBS_VALUE']]
    df['TIME_PERIOD'] = pd.to_datetime(df['TIME_PERIOD'])
    df['OBS_VALUE'] = pd.to_numeric(df['OBS_VALUE'], errors='coerce')

    # Define the output directory and ensure it exists
    output_dir = 'MX'
    os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'fred_data.csv')

    # Save the DataFrame to a CSV file in the specified folder
    df.to_csv(output_file, index=False)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    inflation()
