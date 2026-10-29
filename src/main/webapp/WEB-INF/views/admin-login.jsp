<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Admin Login"/>
    <jsp:param name="nav" value="adminlogin"/>
</jsp:include>

<div class="container">
    <div class="card form-card narrow">
        <h2>Administrator login</h2>
        <p class="muted">Restricted area for blood bank staff.</p>
        <c:if test="${not empty error}">
            <div class="alert alert-error"><c:out value="${error}"/></div>
        </c:if>
        <form action="${ctx}/admin-login" method="post">
            <input type="hidden" name="csrf" value="${sessionScope.csrf}">
            <div class="field" style="margin-bottom:14px">
                <label for="username">Username</label>
                <input type="text" id="username" name="username" required value="<c:out value='${param.username}'/>">
            </div>
            <div class="field" style="margin-bottom:18px">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
            </div>
            <button type="submit" class="btn" style="width:100%">Log in</button>
        </form>
    </div>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
