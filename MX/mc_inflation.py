import os
import requests
import pandas as pd

# INEGI_API_KEY = '446548c3-7b55-4b22-8430-ac8f251ea555'

def inflation():
    # Retrieve the INEGI API key from environment variables
    INEGI_API_KEY = os.getenv('INEGI_API_KEY')
    SERIES_ID = '910406,910407,910410'  # Your INEGI series ID
    INEGI_URL = f'https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/{SERIES_ID}/es/0700/false/BIE/2.0/{INEGI_API_KEY}?type=json'

    # Fetch data from the INEGI API
    response = requests.get(INEGI_URL)
    response.raise_for_status()  # Raise an error if the response status is not 200
    data = response.json()
    
    observations = data.get('Series', {})
    if not observations:
        raise ValueError(f"No observations found for series ID {SERIES_ID}")

    # Create DataFrames from each set of observations and rename the OBS_VALUE column based on the indicator
    dfs = []
    for obs in observations:
        indicator = obs['INDICADOR']
        df = pd.DataFrame(obs.get('OBSERVATIONS', []))
    
        # Check if required columns are present
        if 'TIME_PERIOD' in df.columns and 'OBS_VALUE' in df.columns:
            df = df[['TIME_PERIOD', 'OBS_VALUE']]  # Select relevant columns
            df['TIME_PERIOD'] = pd.to_datetime(df['TIME_PERIOD'])  # Convert TIME_PERIOD to datetime
            df[f'{indicator}'] = pd.to_numeric(df['OBS_VALUE'], errors='coerce')  # Rename OBS_VALUE and convert to numeric
            df = df.drop(columns=['OBS_VALUE'])  # Drop the original OBS_VALUE column
    
            dfs.append(df)  # Append the modified DataFrame to the list
            
    # Sequentially merge all DataFrames in dfs on TIME_PERIOD using an outer join
    merged_df = dfs[0]  # Start with the first DataFrame
    for df in dfs[1:]:
        merged_df = pd.merge(merged_df, df, on='TIME_PERIOD', how='outer')  # Merge with the next DataFrame

    merged_df.columns = ['TIME_PERIOD', 'Inflación general', 'Subyacente', 'No subyacente']

    # Filter since 2018
    merged_df = merged_df[merged_df['TIME_PERIOD'] >= '2018-01-01']
    
    # Define the output directory and ensure it exists
    output_dir = 'MX'
    os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'mc_inflation.csv')

    # Save the merged DataFrame to a CSV file in the specified folder
    merged_df.to_csv(output_file, index=False)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    inflation()
