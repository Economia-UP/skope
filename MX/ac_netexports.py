import os
import requests
import pandas as pd

# INEGI_API_KEY = '446548c3-7b55-4b22-8430-ac8f251ea555'

def netexports():
    # Retrieve the INEGI API key from environment variables
    INEGI_API_KEY = os.getenv('INEGI_API_KEY')
    SERIES_ID = '727431,727418'  # Your INEGI series ID
    INEGI_URL = f'https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/{SERIES_ID}/es/0700/false/BIE/2.0/{INEGI_API_KEY}?type=json'

    # Fetch data from the INEGI API
    response = requests.get(INEGI_URL)
    response.raise_for_status()  # Raise an error if the response status is not 200
    data = response.json()

    observations1 = data.get('Series', {})[0].get('OBSERVATIONS')
    if not observations1:
        raise ValueError(f"No observations found for series ID {SERIES_ID}")

    observations2 = data.get('Series', {})[1].get('OBSERVATIONS')
    if not observations2:
        raise ValueError(f"No observations found for series ID {SERIES_ID}")    

    df1 = pd.DataFrame(observations1)
    df1 = df1[['TIME_PERIOD', 'OBS_VALUE']]  # Select relevant columns
    df1['OBS_VALUE'] = pd.to_numeric(df1['OBS_VALUE'], errors='coerce')  # Rename OBS_VALUE and convert to numeric
    df1['TIME_PERIOD'] = pd.to_datetime(df1['TIME_PERIOD'], errors = 'coerce')     

    
    df2 = pd.DataFrame(observations2)
    df2 = df2[['TIME_PERIOD', 'OBS_VALUE']]  # Select relevant columns
    df2['OBS_VALUE'] = pd.to_numeric(df2['OBS_VALUE'], errors='coerce')  # Rename OBS_VALUE and convert to numeric
    df2['TIME_PERIOD'] = pd.to_datetime(df2['TIME_PERIOD'], errors = 'coerce') 
    
    df = df1.merge(df2, on = 'TIME_PERIOD', how='outer')    
    df = df.rename(columns = {'TIME_PERIOD':'fecha'})

    # Filter since 2018
    df = df[df['fecha'] >= '2018-01-01']

    # Change name of columns
    df.columns = ['fecha', 'Exportaciones', 'Importaciones']
    df.sort_values(by='fecha', ascending=True, inplace=True)
    
    df['Exportaciones netas'] = df['Exportaciones'] - df['Importaciones']

    # Define the output directory and ensure it exists
    output_dir = 'MX'
    # os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'ac_netexports.csv')

    # Save the merged DataFrame to a CSV file in the specified folder
    df.to_csv(output_file, index=False)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    netexports()
