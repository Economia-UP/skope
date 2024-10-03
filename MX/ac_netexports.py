import os
import requests
import pandas as pd

# INEGI_API_KEY = '446548c3-7b55-4b22-8430-ac8f251ea555'

def netexports():
    # Retrieve the INEGI API key from environment variables
    INEGI_API_KEY = os.getenv('INEGI_API_KEY')
    SERIES_ID = '87537'  # Your INEGI series ID
    # SERIES_ID = '727431,727418'  # Your INEGI series ID
    INEGI_URL = f'https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/{SERIES_ID}/es/0700/false/BIE/2.0/{INEGI_API_KEY}?type=json'

    # Fetch data from the INEGI API
    response = requests.get(INEGI_URL)
    response.raise_for_status()  # Raise an error if the response status is not 200
    data = response.json()

    observations = data.get('Series', {})[0].get('OBSERVATIONS')
    if not observations:
        raise ValueError(f"No observations found for series ID {SERIES_ID}")
   

    df = pd.DataFrame(observations)
    df = df[['TIME_PERIOD', 'OBS_VALUE']]  # Select relevant columns
    df['OBS_VALUE'] = pd.to_numeric(df['OBS_VALUE'], errors='coerce')  # Rename OBS_VALUE and convert to numeric
    df['TIME_PERIOD'] = pd.to_datetime(df['TIME_PERIOD'], format = '%Y/%m', errors = 'coerce')     
    
    df = df.rename(columns = {'TIME_PERIOD':'fecha'})
    df.columns = ['fecha', 'Exportaciones netas']
    
    # # Define los rangos de fechas para los sexenios
    # sexenios = {
    #     '2000-2006': (pd.to_datetime('2000-12-01'), pd.to_datetime('2006-11-30')),
    #     '2006-2012': (pd.to_datetime('2006-12-01'), pd.to_datetime('2012-11-30')),
    #     '2012-2018': (pd.to_datetime('2012-12-01'), pd.to_datetime('2018-09-30')),
    #     '2018-2024': (pd.to_datetime('2018-12-01'), pd.to_datetime('2024-09-30')),
    #     '2024-2030': (pd.to_datetime('2018-10-01'), pd.to_datetime('2030-09-30'))
    # }
    
    # # Función para asignar cada fecha a su sexenio correspondiente
    # def asignar_sexenio(fecha):
    #     for sexenio, (inicio, fin) in sexenios.items():
    #         if inicio <= fecha <= fin:
    #             return sexenio
    #     return None
    
    # # Aplica la función para crear una nueva columna 'sexenio'
    # df['sexenio'] = df['fecha'].apply(asignar_sexenio)
    
    # # Filtra solo las filas que pertenecen a un sexenio válido
    # df = df[df['sexenio'].notna()]
    
    df = df[df['fecha'] >= '2018-01-01']
    
    meses_abreviados = {
        1: 'ene', 2: 'feb', 3: 'mar', 4: 'abr', 5: 'may', 6: 'jun',
        7: 'jul', 8: 'ago', 9: 'sep', 10: 'oct', 11: 'nov', 12: 'dic'
    }
    
    # Función para obtener el mes en formato abreviado
    def obtener_mes_abreviado(fecha):
        return meses_abreviados[fecha.month]
    
    # Aplica la función para crear la columna 'mes_abreviado'
    df['mes_abreviado'] = df['fecha'].apply(obtener_mes_abreviado)

    
    df['año'] = df['fecha'].dt.year
    
    # Ordena el DataFrame por año y por fecha
    df.sort_values(by=['fecha'], inplace=True)
    
    # Convertir 'mes_abreviado' a tipo categórico con un orden específico
    df['mes_abreviado'] = pd.Categorical(df['mes_abreviado'], 
                                          categories=list(meses_abreviados.values()), 
                                          ordered=True)
    
    # Pivot the DataFrame to wide format: months as index and years as columns
    df_wide = df.pivot(index='mes_abreviado', columns='año', 
                       values='Exportaciones netas')
        
    # Cumsum    
    df_wide = df_wide.cumsum()

    # Define the output directory and ensure it exists
    output_dir = 'MX'
    # os.makedirs(output_dir, exist_ok=True)  # Create the directory if it doesn't exist
    output_file = os.path.join(output_dir, 'ac_netexports.csv')

    # Save the merged DataFrame to a CSV file in the specified folder
    df_wide.to_csv(output_file, index=True)
    print(f"Data successfully written to {output_file}")

if __name__ == "__main__":
    netexports()
