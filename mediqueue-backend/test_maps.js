async function main() {
  const urls = [
    "https://maps.app.goo.gl/1xyZ", 
    "https://www.google.com/maps/place/Some+Hospital/@12.9559384,77.5332569,15z",
    "https://www.google.com/maps/place/13%C2%B003'13.1%22N+77%C2%B032'15.4%22E/@13.0536417,77.534958,18z/data=!4m4!3m3!8m2!3d13.0536417!4d77.537632?entry=ttu"
  ];
  
  for (const link of urls) {
     console.log("Analyzing:", link);
     /* 
     let finalUrl = link;
     if (link.includes('maps.app.goo.gl') || link.includes('goo.gl')) {
         const resp = await fetch(link, { redirect: 'follow' });
         finalUrl = resp.url;
     } 
     This is skipping actual fetch for mock short links but demonstrating regex logic 
     */
     let finalUrl = link; 
     if(link === "https://maps.app.goo.gl/1xyZ") finalUrl = "https://www.google.com/maps/place/XYZ/@12.123,77.123,15z";
     
     let lat = null, lon = null;
     
     const atMatch = finalUrl.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/);
     if (atMatch) {
         lat = parseFloat(atMatch[1]);
         lon = parseFloat(atMatch[2]);
     } else {
         const dMatch = finalUrl.match(/!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)/);
         if (dMatch) {
             lat = parseFloat(dMatch[1]);
             lon = parseFloat(dMatch[2]);
         }
     }
     console.log(`Extracted: Lat=${lat}, Lon=${lon}`);
  }
}
main();
