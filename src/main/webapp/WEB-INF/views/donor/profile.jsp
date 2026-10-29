<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="My Profile"/>
    <jsp:param name="nav" value="donor"/>
</jsp:include>

<%-- After a failed save we show what the user typed; otherwise the stored values. --%>
<c:set var="redo" value="${not empty errors}"/>

<div class="container">
    <div class="card form-card">
        <h2>My profile</h2>
        <p class="muted">Email (<strong><c:out value="${me.email}"/></strong>) and blood group
            (<strong><c:out value="${me.bloodGroup}"/></strong>) cannot be changed. Contact the blood bank if they are wrong.</p>

        <c:if test="${redo}">
            <div class="alert alert-error">
                <ul><c:forEach var="e" items="${errors}"><li><c:out value="${e}"/></li></c:forEach></ul>
            </div>
        </c:if>

        <form action="${ctx}/donor/profile" method="post">
            <input type="hidden" name="csrf" value="${sessionScope.csrf}">
            <div class="form-grid">
                <div class="field full">
                    <label for="fullName">Full name</label>
                    <input type="text" id="fullName" name="fullName" required minlength="2" maxlength="80"
                           value="<c:out value='${redo ? param.fullName : me.fullName}'/>">
                </div>
                <div class="field">
                    <label for="phone">Mobile number</label>
                    <input type="tel" id="phone" name="phone" required pattern="[0-9]{10}" maxlength="10"
                           value="<c:out value='${redo ? param.phone : me.phone}'/>">
                </div>
                <div class="field">
                    <label for="city">City</label>
                    <input type="text" id="city" name="city" required maxlength="60"
                           value="<c:out value='${redo ? param.city : me.city}'/>">
                </div>
                <c:set var="g" value="${redo ? param.gender : me.gender}"/>
                <div class="field">
                    <label for="gender">Gender</label>
                    <select id="gender" name="gender" required>
                        <option value="M" ${g == 'M' ? 'selected' : ''}>Male</option>
                        <option value="F" ${g == 'F' ? 'selected' : ''}>Female</option>
                        <option value="O" ${g == 'O' ? 'selected' : ''}>Other</option>
                    </select>
                </div>
                <div class="field">
                    <label for="dob">Date of birth</label>
                    <input type="date" id="dob" name="dob" required
                           value="<c:out value='${redo ? param.dob : me.dob}'/>">
                </div>
            </div>
            <p style="margin-top:20px"><button type="submit" class="btn">Save changes</button></p>
        </form>
    </div>

    <div class="card form-card">
        <h2>Change password</h2>
        <form action="${ctx}/donor/password" method="post">
            <input type="hidden" name="csrf" value="${sessionScope.csrf}">
            <div class="form-grid">
                <div class="field full">
                    <label for="currentPassword">Current password</label>
                    <input type="password" id="currentPassword" name="currentPassword" required autocomplete="current-password">
                </div>
                <div class="field">
                    <label for="newPassword">New password</label>
                    <input type="password" id="newPassword" name="newPassword" required minlength="8" autocomplete="new-password">
                </div>
                <div class="field">
                    <label for="confirmPassword">Confirm new password</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" required minlength="8" autocomplete="new-password">
                </div>
            </div>
            <p style="margin-top:20px"><button type="submit" class="btn btn-outline">Change password</button></p>
        </form>
    </div>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
