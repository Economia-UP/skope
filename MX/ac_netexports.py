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

    df.columns = ['fecha', 'Exportaciones', 'Importaciones']
    df['Exportaciones netas'] = df['Exportaciones'] - df['Importaciones']
    
    # Define los rangos de fechas para los sexenios
    sexenios = {
        '2000-2006': (pd.to_datetime('2000-12-01'), pd.to_datetime('2006-11-30')),
        '2006-2012': (pd.to_datetime('2006-12-01'), pd.to_datetime('2012-11-30')),
        '2012-2018': (pd.to_datetime('2012-12-01'), pd.to_datetime('2018-09-30')),
        '2018-2024': (pd.to_datetime('2018-12-01'), pd.to_datetime('2024-09-30')),
        '2024-2030': (pd.to_datetime('2018-10-01'), pd.to_datetime('2030-09-30'))
    }
    
    # Función para asignar cada fecha a su sexenio correspondiente
    def asignar_sexenio(fecha):
        for sexenio, (inicio, fin) in sexenios.items():
            if inicio <= fecha <= fin:
                return sexenio
        return None
    
    # Aplica la función para crear una nueva columna 'sexenio'
    df['sexenio'] = df['fecha'].apply(asignar_sexenio)
    
    # Filtra solo las filas que pertenecen a un sexenio válido
    df = df[df['sexenio'].notna()]
    
    # Función para calcular el año relativo dentro del sexenio
    def calcular_año_relativo(fecha, sexenio):
        inicio_sexenio = sexenios[sexenio][0]
        return (fecha.year - inicio_sexenio.year)
    
    # Aplica la función para crear la columna 'año_relativo'
    df['año_relativo'] = df.apply(lambda row: calcular_año_relativo(row['fecha'], row['sexenio']), axis=1)

    
    # Ordena el DataFrame por sexenio y por fecha
    df.sort_values(by=['sexenio', 'fecha'], inplace=True)
    
    # Selecciona las columnas relevantes para comparar los datos por sexenio
    df = df[['sexenio', 'año_relativo', 'Exportaciones', 'Importaciones', 'Exportaciones netas']]

    df_wide = df.pivot(index='año_relativo', columns='sexenio', 
                       values='Exportaciones netas')
    
    # Rename the columns to only include the sexenio names
    df_wide.columns = [f'{sexenio}' for sexenio in df_wide.columns]

    # Define the output directory and ensure it exists
    output_dir = 'MX'
    # os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'ac_netexports.csv')

    # Save the merged DataFrame to a CSV file in the specified folder
    df_wide.to_csv(output_file, index=True)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    netexports()
