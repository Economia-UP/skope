import os
import requests
import pandas as pd

# INEGI_API_KEY = '446548c3-7b55-4b22-8430-ac8f251ea555'

def gdp():
    # Retrieve the INEGI API key from environment variables
    INEGI_API_KEY = os.getenv('INEGI_API_KEY')
    SERIES_ID = '733692,733682,733676,733679,733687,733688,733801,733802,733822,733827,733836,733837,733846,733842,733854'  # Your INEGI series ID
    INEGI_URL = f'https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/{SERIES_ID}/es/0700/false/BIE/2.0/{INEGI_API_KEY}?type=json'

    # Fetch data from the INEGI API
    response = requests.get(INEGI_URL)
    response.raise_for_status()  # Raise an error if the response status is not 200
    data = response.json()

    # Define the function to convert quarter strings to datetime
    def quarter_to_date(quarter_str):
        year, quarter = quarter_str.split('/')
        month = (int(quarter) - 1) * 3 + 1  # Calculate the starting month of the quarter
        return pd.Timestamp(year=int(year), month=month, day=1)
    
    # Create the initial DataFrame with quarterly dates
    dfs = pd.DataFrame({'fecha': pd.date_range(start='2018-01-01', end=pd.Timestamp.today())})
    
    # Loop through each series in the data['Series'] dictionary
    for i in range(len(data.get('Series', []))):
        # Get the 'OBSERVATIONS' and 'INDICADOR'
        observations = data.get('Series', [])[i].get('OBSERVATIONS', [])
        indicador = data.get('Series', [])[i].get('INDICADOR', f'INDICADOR_{i}')  # Fallback in case INDICADOR is missing
        
        # Create DataFrame from the observations
        df = pd.DataFrame(observations)
        
        # Select and rename relevant columns
        df = df[['TIME_PERIOD', 'OBS_VALUE']]  # Select relevant columns
        
        # Apply the function to the TIME_PERIOD column
        df['TIME_PERIOD'] = df['TIME_PERIOD'].apply(quarter_to_date)        
    
        # Convert OBS_VALUE to numeric
        df[indicador] = pd.to_numeric(df['OBS_VALUE'], errors='coerce')  
        
        # Rename TIME_PERIOD to 'fecha' for merging
        df = df.rename(columns={'TIME_PERIOD': 'fecha'})
        
        # Merge with dfs based on 'fecha'
        dfs = dfs.merge(df[['fecha', indicador]], how='outer', on='fecha')
    
    # Filter since 2018
    dfs = dfs[dfs['fecha'] >= '2018-01-01']
        
    # Set 'fecha' as the index
    dfs = dfs.set_index('fecha')
    
    dfs.dropna(inplace=True)
    # Calculate year-over-year percentage change
    dfs = dfs.pct_change(periods=4) * 100  # Multiply by 100 to get percentages
    
    dfs.columns = ['Agricultura', 'Pesca', 'Minería', 'Electricidad', 
                   'Construcción', 'Manufactura', 'Comercio al por mayor', 
                   'Comercio al por menor', 'Finanzas', 'Inmobiliario', 
                   'Educación', 'Salud', 'Recreación', 'Hospitalidad', 'Gobierno']
    dfs = dfs.iloc[-1,:]
    
    # Define the output directory and ensure it exists
    output_dir = 'MX'
    os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'ac_gdpsector.csv')
    
    # Save the merged DataFrame to a CSV file in the specified folder
    dfs.to_csv(output_file, index=True)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    gdp()
