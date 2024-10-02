import os
import requests
import pandas as pd

# BANXICO_API_KEY = '86d02771fd6b64ce29912469f70d872cf666627201a5d7e819a82c452ae61289'

def gdp():
    # Retrieve the INEGI API key from environment variables
    BANXICO_API_KEY = os.getenv('BANXICO_API_KEY')
    SERIES_ID = 'SR17622'  # Your FRED series ID
    BANXICO_URL = f'https://www.banxico.org.mx/SieAPIRest/service/v1/series/{SERIES_ID}/datos?token={BANXICO_API_KEY}&mediaType=json'

    # Fetch data from the BANXICO API
    response = requests.get(BANXICO_URL)
    response.raise_for_status()  # Raise an error if the response status is not 200
    data = response.json()
    
    observations = data.get('bmx').get('series')[0].get('datos')
    if not observations:
        raise ValueError(f"No observations found for series ID {SERIES_ID}")

    df = pd.DataFrame(observations)
    df['fecha'] = pd.to_datetime(df['fecha'], format='%d/%m/%Y', errors = 'coerce')  # Convert TIME_PERIOD to datetime
    df['dato'] = pd.to_numeric(df['dato'].str.replace(',', ''), errors='coerce')

    # Filter since 2018
    df = df[df['fecha'] >= '2020-09-01']

    # Change name of columns
    df.columns = ['fecha', 'PIB trimestral']
    
    # Sacar variación interanual
    index = pd.date_range(start='2020-09-01', periods=len(df['fecha']), freq='Q')
    df = df.set_index(index)

    df['Crecimiento económico'] = df['PIB trimestral'].pct_change(periods=1) * 100  # Multiply by 100 for percentage
    
    # Define the output directory and ensure it exists
    output_dir = 'MX'
    os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'ac_gdpquarter.csv')

    # Save the merged DataFrame to a CSV file in the specified folder
    df.to_csv(output_file, index=False)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    gdp()
