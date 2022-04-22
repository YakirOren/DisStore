
<br/>
<div align="center">
<B>      <img width="15%" src="https://cdn.discordapp.com/attachments/588014716144713739/834791740266250250/Discord-Logo-Color2.png" alt="DisStore logo"></b>
</div>

<br/>


<div align="center">
 <b> Store unlimited files on Discord's CDN. </b>
<br>

</div>



```mermaid
 sequenceDiagram  
    participant Discord
    participant User  
    participant Server
      
    User->>Server: Get file X    
    Server-->>User: A list of links   
    
    loop Retrive File  
		User->>Discord: GET chunk    
		Discord-->>User: chunk content
    end 

	User->>User: conbines chunks into one file
   
```


## 🚀 Examples
<div align="left">


<img src="https://cdn.discordapp.com/attachments/588014716144713739/863802824093335572/fileUpload.gif" height="600" />

<img src="https://cdn.discordapp.com/attachments/588014716144713739/863802815029575700/fileDownload.gif" height="600" />
 </div>






## 🖥 Technology stack

### made using

* Go
* MongoDB
* gRPC
* Flutter
* JWT







