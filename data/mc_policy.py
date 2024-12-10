import os
import requests
import pandas as pd
from datetime import datetime

# BANXICO_API_KEY = '86d02771fd6b64ce29912469f70d872cf666627201a5d7e819a82c452ae61289'
# INEGI_API_KEY = '446548c3-7b55-4b22-8430-ac8f251ea555'

def policy():
    # Retrieve the INEGI API key from environment variables
    BANXICO_API_KEY = os.getenv('BANXICO_API_KEY')
    INEGI_API_KEY = os.getenv('INEGI_API_KEY')

    REFERENCE_ID = 'SF61745'  # Your BANXICO series ID
    REFERENCE = f'https://www.banxico.org.mx/SieAPIRest/service/v1/series/{REFERENCE_ID}/datos?token={BANXICO_API_KEY}&mediaType=json'
    INFLATION_ID = '910406' # Your INEGI series ID
    INFLATION = f'https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/{INFLATION_ID}/es/0700/false/BIE/2.0/{INEGI_API_KEY}?type=json'
    EXPECTATIONS_ID = 'SR14194'  # Your BANXICO series ID
    EXPECTATIONS = f'https://www.banxico.org.mx/SieAPIRest/service/v1/series/{EXPECTATIONS_ID}/datos?token={BANXICO_API_KEY}&mediaType=json'
    
    # Fetch data from the BANXICO API
    response1 = requests.get(REFERENCE)
    response1.raise_for_status()  # Raise an error if the response status is not 200
    data1 = response1.json()

    observations1 = data1.get('bmx').get('series')[0].get('datos')
    if not observations1:
        raise ValueError(f"No observations found for series ID {REFERENCE_ID}")

    # Fetch data from the INEGI API
    response2 = requests.get(INFLATION)
    response2.raise_for_status()  # Raise an error if the response status is not 200
    data2 = response2.json()

    observations2 = data2.get('Series', {})[0].get('OBSERVATIONS')
    if not observations2:
        raise ValueError(f"No observations found for series ID {INFLATION_ID}")

    # Fetch data from the BANXICO API
    response3 = requests.get(EXPECTATIONS)
    response3.raise_for_status()  # Raise an error if the response status is not 200
    data3 = response3.json()

    observations3 = data3.get('bmx').get('series')[0].get('datos')
    if not observations3:
        raise ValueError(f"No observations found for series ID {EXPECTATIONS_ID}")    


    df1 = pd.DataFrame(observations1)
    df1['fecha'] = pd.to_datetime(df1['fecha'], format='%d/%m/%Y', errors='coerce')
    df1['dato'] = pd.to_numeric(df1['dato'].str.replace(',', ''), errors='coerce')

    df2 = pd.DataFrame(observations2)
    df2 = df2[['TIME_PERIOD', 'OBS_VALUE']]  # Select relevant columns
    df2['TIME_PERIOD'] = pd.to_datetime(df2['TIME_PERIOD'])  # Convert TIME_PERIOD to datetime
    df2['OBS_VALUE'] = pd.to_numeric(df2['OBS_VALUE'], errors='coerce')  # Rename OBS_VALUE and convert to numeric
    df2 = df2.rename(columns = {'TIME_PERIOD':'fecha'})

    df3 = pd.DataFrame(observations3)
    df3['fecha'] = pd.to_datetime(df3['fecha'], format='%d/%m/%Y', errors='coerce')
    df3['dato'] = pd.to_numeric(df3['dato'].str.replace(',', ''), errors='coerce')
    
    # Filter since 2018
    df1 = df1[df1['fecha'] >= '2010-01-01']
    df2 = df2[df2['fecha'] >= '2010-01-01']
    df3 = df3[df3['fecha'] >= '2010-01-01']

    start_date = '2010-01-01'
    end_date = datetime.today().strftime('%Y-%m-%d')
    date_range = pd.date_range(start=start_date, end=end_date, freq='D')
    df_dates = pd.DataFrame(date_range, columns=['fecha'])

    dfs = df_dates.merge(df1, how='outer', on='fecha')
    dfs = dfs.merge(df2, how='outer', on='fecha')
    dfs = dfs.merge(df3, how='outer', on='fecha')
    
    dfs = dfs.sort_values(by='fecha')  # Ensure data is sorted by date
    dfs = dfs.ffill()  # Forward fill the missing values
    
    dfs.columns = ['fecha', 'Tasa objetivo', 'Inflación', 'Inflación esperada']

    dfs['Tasa real (ex-post)'] = dfs['Tasa objetivo'] - dfs['Inflación']
    dfs['Tasa real (ex-ante)'] = dfs['Tasa objetivo'] - dfs['Inflación esperada']
    
    # Define the output directory and ensure it exists
    output_dir = 'MX'
    os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'mc_policy.csv')

    # Save the merged DataFrame to a CSV file in the specified folder
    dfs.to_csv(output_file, index=False)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    policy()