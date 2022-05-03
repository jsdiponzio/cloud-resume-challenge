fetch('https://us-east1-jess-cloud-resume-challenge.cloudfunctions.net/increment-fetch')
    .then(response => response.text())
    .then(data => document.getElementById("count").innerHTML = data) 