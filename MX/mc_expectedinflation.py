import os
import requests
import pandas as pd

# BANXICO_API_KEY = '86d02771fd6b64ce29912469f70d872cf666627201a5d7e819a82c452ae61289'

def EXP_LOWER():
    # Retrieve the INEGI API key from environment variables
    BANXICO_API_KEY = os.getenv('BANXICO_API_KEY')
    
    EXP_LOWER_ID = 'SR14196'  # Your BANXICO series ID
    EXP_LOWER = f'https://www.banxico.org.mx/SieAPIRest/service/v1/series/{EXP_LOWER_ID}/datos?token={BANXICO_API_KEY}&mediaType=json'
    EXP_UPPER_ID = 'SR14197'  # Your BANXICO series ID
    EXP_UPPER = f'https://www.banxico.org.mx/SieAPIRest/service/v1/series/{EXP_UPPER_ID}/datos?token={BANXICO_API_KEY}&mediaType=json'
    
    # Fetch data from the BANXICO API
    response1 = requests.get(EXP_LOWER)
    response1.raise_for_status()  # Raise an error if the response status is not 200
    data1 = response1.json()

    observations1 = data1.get('bmx').get('series')[0].get('datos')
    if not observations1:
        raise ValueError(f"No observations found for series ID {EXP_LOWER_ID}")

    response2 = requests.get(EXP_UPPER)
    response2.raise_for_status()  # Raise an error if the response status is not 200
    data2 = response2.json()

    observations2 = data2.get('bmx').get('series')[0].get('datos')
    if not observations2:
        raise ValueError(f"No observations found for series ID {EXP_UPPER_ID}")    


    df1 = pd.DataFrame(observations1)
    df1['fecha'] = pd.to_datetime(df1['fecha'], format='%d/%m/%Y', errors='coerce')
    df1['dato'] = pd.to_numeric(df1['dato'].str.replace(',', ''), errors='coerce')

    df2 = pd.DataFrame(observations2)
    df2['fecha'] = pd.to_datetime(df2['fecha'], format='%d/%m/%Y', errors='coerce')
    df2['dato'] = pd.to_numeric(df2['dato'].str.replace(',', ''), errors='coerce')
    
    # Filter since 2024
    df1 = df1[df1['fecha'] >= '2024-01-01']
    df2 = df2[df2['fecha'] >= '2024-01-01']

    dfs = df1.merge(df2, how='outer', on='fecha')
    dfs.columns = ['fecha', 'Primer cuartil', 'Tercer cuartil']
    
    # Define the output directory and ensure it exists
    output_dir = 'MX'
    os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'mc_internationalEXP_UPPER.csv')

    # Save the merged DataFrame to a CSV file in the specified folder
    dfs.to_csv(output_file, index=False)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    EXP_LOWER()
