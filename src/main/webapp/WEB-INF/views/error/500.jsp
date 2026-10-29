<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" isErrorPage="true" %>
<jsp:include page="/WEB-INF/views/common/header.jsp"><jsp:param name="title" value="Something went wrong"/></jsp:include>
<div class="container error-page">
    <div class="code">500</div>
    <h2>Something went wrong</h2>
    <p class="muted">An unexpected error occurred. Please check that MySQL is running and that the settings in
        <code>db.properties</code> are correct, then try again.</p>
    <a class="btn" href="${ctx}/home">Back to home</a>
</div>
<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
