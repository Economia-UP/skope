import os
import requests
import pandas as pd

# BANXICO_API_KEY = '86d02771fd6b64ce29912469f70d872cf666627201a5d7e819a82c452ae61289'

def AGGREGATES():
    # Retrieve the INEGI API key from environment variables
    BANXICO_API_KEY = os.getenv('BANXICO_API_KEY')
    
    M1_ID = 'SF311408'  # Your BANXICO series ID
    M1 = f'https://www.banxico.org.mx/SieAPIRest/service/v1/series/{M1_ID}/datos?token={BANXICO_API_KEY}&mediaType=json'
    M2_ID = 'SF311418'  # Your BANXICO series ID
    M2 = f'https://www.banxico.org.mx/SieAPIRest/service/v1/series/{M2_ID}/datos?token={BANXICO_API_KEY}&mediaType=json'
    
    # Fetch data from the BANXICO API
    response1 = requests.get(M1)
    response1.raise_for_status()  # Raise an error if the response status is not 200
    data1 = response1.json()

    observations1 = data1.get('bmx').get('series')[0].get('datos')
    if not observations1:
        raise ValueError(f"No observations found for series ID {M1_ID}")

    response2 = requests.get(M2)
    response2.raise_for_status()  # Raise an error if the response status is not 200
    data2 = response2.json()

    observations2 = data2.get('bmx').get('series')[0].get('datos')
    if not observations2:
        raise ValueError(f"No observations found for series ID {M2_ID}")    


    df1 = pd.DataFrame(observations1)
    df1['fecha'] = pd.to_datetime(df1['fecha'], format='%d/%m/%Y', errors='coerce')
    df1['dato'] = pd.to_numeric(df1['dato'].str.replace(',', ''), errors='coerce')

    df2 = pd.DataFrame(observations2)
    df2['fecha'] = pd.to_datetime(df2['fecha'], format='%d/%m/%Y', errors='coerce')
    df2['dato'] = pd.to_numeric(df2['dato'].str.replace(',', ''), errors='coerce')
    
    # Filter since 2017
    df1 = df1[df1['fecha'] >= '2010-01-01']
    df2 = df2[df2['fecha'] >= '2010-01-01']

    dfs = df1.merge(df2, how='outer', on='fecha')
    dfs.columns = ['fecha', 'M1 (datos)', 'M2 (datos)']

    # Calculate pct_change
    index = pd.date_range(start='2017-01-01', periods=len(dfs['fecha']), freq='M')
    dfs = dfs.set_index(index)

    dfs['M1'] = dfs['M1 (datos)'].pct_change(periods=12) * 100  # Multiply by 100 for percentage
    dfs['M2'] = dfs['M2 (datos)'].pct_change(periods=12) * 100  # Multiply by 100 for percentage

    # Define the output directory and ensure it exists
    output_dir = 'MX'
    os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'mc_monetaryaggregates.csv')

    # Save the merged DataFrame to a CSV file in the specified folder
    dfs.to_csv(output_file, index=False)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    AGGREGATES()
