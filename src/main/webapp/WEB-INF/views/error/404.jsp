<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" isErrorPage="true" %>
<jsp:include page="/WEB-INF/views/common/header.jsp"><jsp:param name="title" value="Page not found"/></jsp:include>
<div class="container error-page">
    <div class="code">404</div>
    <h2>Page not found</h2>
    <p class="muted">The page you are looking for does not exist or was moved.</p>
    <a class="btn" href="${ctx}/home">Back to home</a>
</div>
<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
