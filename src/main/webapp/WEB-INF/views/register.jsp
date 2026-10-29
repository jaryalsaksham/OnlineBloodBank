<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Become a Donor"/>
    <jsp:param name="nav" value="register"/>
</jsp:include>

<div class="container">
    <div class="card form-card">
        <h2>Register as a blood donor</h2>
        <p class="muted">Already registered? <a href="${ctx}/login">Log in</a>.</p>

        <c:if test="${not empty errors}">
            <div class="alert alert-error">
                <ul><c:forEach var="e" items="${errors}"><li><c:out value="${e}"/></li></c:forEach></ul>
            </div>
        </c:if>

        <form action="${ctx}/register" method="post" autocomplete="off">
            <input type="hidden" name="csrf" value="${sessionScope.csrf}">
            <div class="form-grid">
                <div class="field full">
                    <label for="fullName">Full name</label>
                    <input type="text" id="fullName" name="fullName" required minlength="2" maxlength="80"
                           value="<c:out value='${param.fullName}'/>">
                </div>
                <div class="field">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" required maxlength="100"
                           value="<c:out value='${param.email}'/>">
                </div>
                <div class="field">
                    <label for="phone">Mobile number</label>
                    <input type="tel" id="phone" name="phone" required pattern="[0-9]{10}" maxlength="10"
                           value="<c:out value='${param.phone}'/>">
                    <div class="hint">10 digits, without country code.</div>
                </div>
                <div class="field">
                    <label for="gender">Gender</label>
                    <select id="gender" name="gender" required>
                        <option value="">Select</option>
                        <option value="M" ${param.gender == 'M' ? 'selected' : ''}>Male</option>
                        <option value="F" ${param.gender == 'F' ? 'selected' : ''}>Female</option>
                        <option value="O" ${param.gender == 'O' ? 'selected' : ''}>Other</option>
                    </select>
                </div>
                <div class="field">
                    <label for="dob">Date of birth</label>
                    <input type="date" id="dob" name="dob" required value="<c:out value='${param.dob}'/>">
                </div>
                <div class="field">
                    <label for="bloodGroup">Blood group</label>
                    <select id="bloodGroup" name="bloodGroup" required>
                        <option value="">Select</option>
                        <c:forEach var="g" items="${bloodGroups}">
                            <option value="${g}" ${param.bloodGroup == g ? 'selected' : ''}>${g}</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="field">
                    <label for="city">City</label>
                    <input type="text" id="city" name="city" required maxlength="60"
                           value="<c:out value='${param.city}'/>">
                </div>
                <div class="field">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" required minlength="8" autocomplete="new-password">
                    <div class="hint">At least 8 characters.</div>
                </div>
                <div class="field">
                    <label for="confirmPassword">Confirm password</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" required minlength="8" autocomplete="new-password">
                </div>
                <div class="field full">
                    <label class="check" style="font-weight:400">
                        <input type="checkbox" name="consent" value="yes" required>
                        <span>I confirm that I am between 18 and 65 years old, in good health, and willing to donate blood.</span>
                    </label>
                </div>
            </div>
            <p style="margin-top:20px"><button type="submit" class="btn">Create account</button></p>
        </form>
    </div>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
