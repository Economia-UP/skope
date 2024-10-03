import os
import requests
import pandas as pd

# INEGI_API_KEY = '446548c3-7b55-4b22-8430-ac8f251ea555'

def gdp():
    # Retrieve the INEGI API key from environment variables
    INEGI_API_KEY = os.getenv('INEGI_API_KEY')
    SERIES_ID = '733671'  # Your INEGI series ID
    INEGI_URL = f'https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/{SERIES_ID}/es/0700/false/BIE/2.0/{INEGI_API_KEY}?type=json'

    # Fetch data from the INEGI API
    response = requests.get(INEGI_URL)
    response.raise_for_status()  # Raise an error if the response status is not 200
    data = response.json()

    observations = data.get('Series', {})[0].get('OBSERVATIONS')
    if not observations:
        raise ValueError(f"No observations found for series ID {SERIES_ID}")
    
    def quarter_to_date(quarter_str):
        year, quarter = quarter_str.split('/')
        month = (int(quarter) - 1) * 3 + 1  # Calculate the starting month of the quarter
        return pd.Timestamp(year=int(year), month=month, day=1)

    df = pd.DataFrame(observations)
    df = df[['TIME_PERIOD', 'OBS_VALUE']]  # Select relevant columns
    df['TIME_PERIOD'] = df['TIME_PERIOD'].apply(quarter_to_date)        
    df['OBS_VALUE'] = pd.to_numeric(df['OBS_VALUE'], errors='coerce')  # Rename OBS_VALUE and convert to numeric
    df = df.rename(columns = {'TIME_PERIOD':'fecha'})

    # Filter since 2018
    df = df[df['fecha'] >= '2020-09-01']

    # Change name of columns
    df.columns = ['fecha', 'PIB trimestral']
    
    # Sacar variación interanual
    df = df.set_index(df['fecha']).dropna()
    df = df.sort_index()

    df['Crecimiento económico'] = df['PIB trimestral'].pct_change(periods=1) * 100  # Multiply by 100 for percentage
    
    # Define the output directory and ensure it exists
    output_dir = 'MX'
    os.makedirs(output_dir, exist_ok=False)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'ac_gdpquarter.csv')

    # Save the merged DataFrame to a CSV file in the specified folder
    df.to_csv(output_file, index=True)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    gdp()
