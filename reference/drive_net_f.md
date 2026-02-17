# Driving network for Edinburgh, filtered around Leith Walk

This dataset contains the driving network for Edinburgh, filtered around
Leith Walk.

## Format

An sf data frame

## Examples

``` r
head(drive_net_f)
#> Simple feature collection with 6 features and 67 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -3.179636 ymin: 55.963 xmax: -3.173373 ymax: 55.9699
#> Geodetic CRS:  WGS 84
#>       osm_id               name      highway waterway aerialway barrier
#> 367  4082270      Smith's Place  residential     <NA>      <NA>    <NA>
#> 1975 4835689        Jane Street unclassified     <NA>      <NA>    <NA>
#> 6285 6176040      Stead's Place  residential     <NA>      <NA>    <NA>
#> 6288 6176068 Springfield Street  residential     <NA>      <NA>    <NA>
#> 6293 6176166      Arthur Street  residential     <NA>      <NA>    <NA>
#> 6295 6176196        Middlefield  residential     <NA>      <NA>    <NA>
#>      man_made  ref oneway maxspeed bicycle cycleway cycleway_left
#> 367      <NA> <NA>   <NA>   20 mph    <NA>     <NA>          <NA>
#> 1975     <NA> <NA>     no   20 mph    <NA>     <NA>          <NA>
#> 6285     <NA> <NA>   <NA>   20 mph    <NA>     <NA>          <NA>
#> 6288     <NA> <NA>   <NA>   20 mph    <NA>     <NA>          <NA>
#> 6293     <NA> <NA>    yes   20 mph    <NA>     <NA>          <NA>
#> 6295     <NA> <NA>     no   20 mph    <NA>     <NA>          <NA>
#>      cycleway_right cycleway_both cycleway_left_bicycle cycleway_right_bicycle
#> 367            <NA>          <NA>                  <NA>                   <NA>
#> 1975           <NA>          <NA>                  <NA>                   <NA>
#> 6285           <NA>          <NA>                  <NA>                   <NA>
#> 6288           <NA>          <NA>                  <NA>                   <NA>
#> 6293           <NA>          <NA>                  <NA>                   <NA>
#> 6295           <NA>          <NA>                  <NA>                   <NA>
#>      cycleway_both_bicycle cycleway_left_segregated cycleway_right_segregated
#> 367                   <NA>                     <NA>                      <NA>
#> 1975                  <NA>                     <NA>                      <NA>
#> 6285                  <NA>                     <NA>                      <NA>
#> 6288                  <NA>                     <NA>                      <NA>
#> 6293                  <NA>                     <NA>                      <NA>
#> 6295                  <NA>                     <NA>                      <NA>
#>      cycleway_both_segregated cycleway_lane cycleway_left_lane
#> 367                      <NA>          <NA>               <NA>
#> 1975                     <NA>          <NA>               <NA>
#> 6285                     <NA>          <NA>               <NA>
#> 6288                     <NA>          <NA>               <NA>
#> 6293                     <NA>          <NA>               <NA>
#> 6295                     <NA>          <NA>               <NA>
#>      cycleway_right_lane cycleway_both_lane cycleway_surface cycleway_width
#> 367                 <NA>               <NA>             <NA>           <NA>
#> 1975                <NA>               <NA>             <NA>           <NA>
#> 6285                <NA>               <NA>             <NA>           <NA>
#> 6288                <NA>               <NA>             <NA>           <NA>
#> 6293                <NA>               <NA>             <NA>           <NA>
#> 6295                <NA>               <NA>             <NA>           <NA>
#>      cycleway_est_width cycleway_buffered_lane lanes lanes_both_ways
#> 367                <NA>                   <NA>  <NA>            <NA>
#> 1975               <NA>                   <NA>  <NA>            <NA>
#> 6285               <NA>                   <NA>  <NA>            <NA>
#> 6288               <NA>                   <NA>     2            <NA>
#> 6293               <NA>                   <NA>     1            <NA>
#> 6295               <NA>                   <NA>  <NA>            <NA>
#>      lanes_forward lanes_backward  lit width est_width segregated foot path
#> 367           <NA>           <NA> <NA>  <NA>      <NA>       <NA> <NA> <NA>
#> 1975          <NA>           <NA> <NA>  <NA>      <NA>       <NA> <NA> <NA>
#> 6285          <NA>           <NA> <NA>  <NA>      <NA>       <NA> <NA> <NA>
#> 6288          <NA>           <NA>  yes  <NA>      <NA>       <NA> <NA> <NA>
#> 6293          <NA>           <NA>  yes  <NA>      <NA>       <NA> <NA> <NA>
#> 6295          <NA>           <NA> <NA>  <NA>      <NA>       <NA> <NA> <NA>
#>      sidewalk sidewalk_left sidewalk_right sidewalk_both footway service
#> 367      <NA>          <NA>           <NA>          <NA>    <NA>    <NA>
#> 1975     <NA>          <NA>           <NA>          <NA>    <NA>    <NA>
#> 6285     <NA>          <NA>           <NA>          <NA>    <NA>    <NA>
#> 6288     both          <NA>           <NA>          <NA>    <NA>    <NA>
#> 6293     both          <NA>           <NA>          <NA>    <NA>    <NA>
#> 6295     <NA>          <NA>           <NA>          <NA>    <NA>    <NA>
#>          surface tracktype smoothness access  bus busway  psv lanes_psv
#> 367      asphalt      <NA>       <NA>   <NA> <NA>   <NA> <NA>      <NA>
#> 1975 cobblestone      <NA>       <NA>   <NA> <NA>   <NA> <NA>      <NA>
#> 6285        <NA>      <NA>       <NA>   <NA> <NA>   <NA> <NA>      <NA>
#> 6288     asphalt      <NA>       <NA>   <NA> <NA>   <NA> <NA>      <NA>
#> 6293     asphalt      <NA>       <NA>   <NA> <NA>   <NA> <NA>      <NA>
#> 6295        sett      <NA>       <NA>   <NA> <NA>   <NA> <NA>      <NA>
#>      lanes_bus lanes_bus_conditional lanes_bus_backward lanes_bus_forward
#> 367       <NA>                  <NA>               <NA>              <NA>
#> 1975      <NA>                  <NA>               <NA>              <NA>
#> 6285      <NA>                  <NA>               <NA>              <NA>
#> 6288      <NA>                  <NA>               <NA>              <NA>
#> 6293      <NA>                  <NA>               <NA>              <NA>
#> 6295      <NA>                  <NA>               <NA>              <NA>
#>      lanes_psv_backward lanes_psv_forward lanes_psv_conditional
#> 367                <NA>              <NA>                  <NA>
#> 1975               <NA>              <NA>                  <NA>
#> 6285               <NA>              <NA>                  <NA>
#> 6288               <NA>              <NA>                  <NA>
#> 6293               <NA>              <NA>                  <NA>
#> 6295               <NA>              <NA>                  <NA>
#>      lanes_psv_conditional_backward lanes_psv_conditional_forward
#> 367                            <NA>                          <NA>
#> 1975                           <NA>                          <NA>
#> 6285                           <NA>                          <NA>
#> 6288                           <NA>                          <NA>
#> 6293                           <NA>                          <NA>
#> 6295                           <NA>                          <NA>
#>      lanes_psv_conditional_both_ways lanes_psv_both_ways z_order
#> 367                             <NA>                <NA>       3
#> 1975                            <NA>                <NA>       3
#> 6285                            <NA>                <NA>       3
#> 6288                            <NA>                <NA>       3
#> 6293                            <NA>                <NA>       3
#> 6295                            <NA>                <NA>       3
#>                       other_tags                       geometry n_bus_lanes
#> 367                         <NA> LINESTRING (-3.174385 55.96...           0
#> 1975                        <NA> LINESTRING (-3.173429 55.96...           0
#> 6285 "not:name"=>"Steads' Place" LINESTRING (-3.174407 55.96...           0
#> 6288                        <NA> LINESTRING (-3.174695 55.96...           0
#> 6293                        <NA> LINESTRING (-3.176535 55.96...           0
#> 6295                        <NA> LINESTRING (-3.178854 55.96...           0
plot(drive_net_f)
#> Warning: plotting the first 9 out of 67 attributes; use max.plot = 67 to plot all
```
