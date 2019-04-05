<html>

<head>
<meta http-equiv="Content-Type"
content="text/html; charset=iso-8859-1">
<meta name="GENERATOR" content="Microsoft FrontPage Express 2.0">
<title>Full Size Image Preview</title>
</head>

<body background="paper2.jpg" bgcolor="#FFFFFF">
<font face="Comic Sans MS"><%FILENAME=Request.QueryString("FILENAME")%></font><font face="Comic Sans MS"><%CAPTION=Request.QueryString("CAPTION")%></font>

<table border="0">
    <tr>
        <td width="450"><p align="center"><font
        face="Comic Sans MS"><img src="<%=FILENAME%>"
        align="middle" border="12" width="300" height="450"></font></p>
        </td>
        <td>&nbsp;</td>
        <td width="250"><p align="center"><font size="4"
        face="Comic Sans MS"><strong><%=CAPTION%></strong></font></p>
        <p align="center"><font size="3" face="Comic Sans MS">Order
        Information</font></p>
        <table border="1">
            <tr>
                <td align="center" width="125"><font
                face="Comic Sans MS">Print Dimensions</font> </td>
                <td align="center" width="100"><font
                face="Comic Sans MS">Price</font> </td>
            </tr>
            <tr>
                <td align="center"><font face="Comic Sans MS">8&quot;
                x 10&quot;</font></td>
                <td align="center"><font face="Comic Sans MS">$39</font></td>
            </tr>
            <tr>
                <td align="center"><font face="Comic Sans MS">11&quot;
                x 14&quot;</font></td>
                <td align="center"><font face="Comic Sans MS">$65</font></td>
            </tr>
            <tr>
                <td align="center"><font face="Comic Sans MS">16&quot;
                x 20&quot;</font></td>
                <td align="center"><font face="Comic Sans MS">$99</font></td>
            </tr>
        </table>
        <p><font size="1" face="Comic Sans MS">Prices are for
        prints only and do not include matting or framing.
        Shipping is $5 for 8 x 10 and 11 x 14, and $8 for 16 x
        20. For questions or pricing for other size prints,
        please send an email to: </font><a
        href="mailto:visionsoftravel@yahoo.com"><font size="1"
        face="Comic Sans MS">visionsoftravel@yahoo.com</font></a></p>
        <p><font size="1" face="Comic Sans MS">To order a print
        send a check made out to Eduardo Pretell to:<br>
        2926 San Juan Boulevard</font><font face="Comic Sans MS">
        <br>
        </font><font size="1" face="Comic Sans MS">Belmont, CA
        94002</font></p>
        <p><font size="1" face="Comic Sans MS">Please include
        your name, address and the title of the image.</font></p>
        <p><font size="1" face="Comic Sans MS">All images are the
        property of Eduardo Pretell and may not be copied,
        printed or otherwise reproduced or used without written
        permission of the owner. Copyright © 1998-1999 Eduardo
        Pretell.</font></p>
        </td>
    </tr>
</table>

<p>&nbsp;</p>
</body>
</html>
