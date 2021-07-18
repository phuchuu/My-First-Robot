*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library   RPA.Browser.Selenium
Library   RPA.HTTP
Library   RPA.Tables
Library   Collections
Library   RPA.PDF
Library   RPA.Archive


*** Variables ***
${popup}            //div[contains(@class, 'modal') and contains(@style, 'display: none')]
${input_legs}       //input[contains(@class, 'form-control') and contains(@min, '1')]
${alert_danger}     //div[contains(@class, 'alert-danger')]

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=  Read Table From Csv    orders.csv   header=True
    [Return]  ${orders}

*** Keywords ***
Close the annoying modal
    ${Status}=   Run Keyword And Return Status    Page Should Not Contain Element    ${popup}
    Run Keyword If    ${Status}       Click Button        //button[contains(@class, 'btn-dark')]

*** Keywords ***
Fill the form
    [Arguments]   ${row}
    Select From List By Value    head   ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input.form-control   ${row}[Legs]
    Input Text    address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button   id:preview
    Wait Until Page Contains Element    //div[contains(@id, 'robot-preview-image')]

*** Keywords ***
Submit the order
    Click Button Order
    ${status}=     Run Keyword And Return Status    Page Should Contain Element    ${alert_danger}
    Run Keyword If    ${status}    Try again if keyword failed    Click Button Order

*** Keywords ***
Try again if keyword failed
    [Arguments]    ${keyword}
    Wait Until Keyword Succeeds    5x    1 sec    ${keyword}

*** Keywords ***
Click Button Order
    Click Button    id:order

*** Keywords ***
Click Button Order Another
    Click Element    id:order-another

*** Keywords ***
Go to order another robot
    ${is_another}=   Run Keyword And Return Status    Page Should Contain Element    id:order-another
    Run Keyword If    ${is_another}    Try again if keyword failed    Click Button Order Another

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]      ${order_number}
    ${status}=     Run Keyword And Return Status    Page Should Contain Element    ${alert_danger}
    Run Keyword If    ${status}    Try again if keyword failed    Click Button Order
    Wait Until Element Is Visible    id:receipt
    ${pdf}=    Set Variable  ${CURDIR}${/}output${/}receipts${/}receipt_${order_number}.pdf
    ${receipt_html}=  Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf}
    [Return]  ${pdf}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]        ${order_number}
    ${status}=     Run Keyword And Return Status    Page Should Contain Element    ${alert_danger}
    Run Keyword If    ${status}    Try again if keyword failed    Click Button Order
    Wait Until Element Is Visible    id:receipt
    ${screenshot}=    Set Variable   ${CURDIR}${/}output${/}images${/}image_${order_number}.png
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}images${/}image_${order_number}.png
    [Return]  ${screenshot}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}     
    ${status}=     Run Keyword And Return Status    Page Should Contain Element    ${alert_danger}
    Run Keyword If    ${status}    Try again if keyword failed    Click Button Order
    Wait Until Element Is Visible    id:receipt 
    Add Watermark Image To PDF
    ...             image_path=${screenshot} 
    ...             source_path=${pdf} 
    ...             output_path=${pdf} 


*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip     ${CURDIR}${/}output${/}receipts     recipes.zip   

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser
