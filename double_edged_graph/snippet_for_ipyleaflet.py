from ipyleaflet import Map, GeoJSON, GeoData
import geopandas, pandas as pd, numpy as np

m = Map(center=(46.91, 7.43), zoom=15)

numpoints = 10
center = (7.43, 46.91)

df = pd.DataFrame(
    {'Conc': 1 * np.random.randn(numpoints) + 17,
     'Longitude': 0.0004 * np.random.randn(numpoints) + center[0],
     'Latitude': 0.0004 * np.random.randn(numpoints) + center[1]})

gdf = geopandas.GeoDataFrame(
    df, geometry=geopandas.points_from_xy(df.Longitude, df.Latitude))

geo_data = GeoData(geo_dataframe = gdf,
    style={'color': 'black', 'radius':8, 'fillColor': '#3366cc', 'opacity':0.5, 'weight':1.9, 'dashArray':'2', 'fillOpacity':0.6},
    hover_style={'fillColor': 'red' , 'fillOpacity': 0.2},
    point_style={'radius': 5, 'color': 'red', 'fillOpacity': 0.8, 'fillColor': 'blue', 'weight': 3},
    name = 'Release')

m.add_layer(geo_data)
m