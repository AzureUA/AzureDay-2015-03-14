<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="Client.Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
		<h1>Client site</h1>
		<h2><%= Newtonsoft.Json.JsonConvert.SerializeObject(new { msg = "greetings" }) %></h2>
    </div>
    </form>
</body>
</html>
