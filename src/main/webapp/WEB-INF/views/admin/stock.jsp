<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Blood Stock"/>
    <jsp:param name="nav" value="admin"/>
</jsp:include>
<jsp:include page="/WEB-INF/views/common/adminnav.jsp"><jsp:param name="tab" value="stock"/></jsp:include>

<div class="container">
    <div class="page-head">
        <h1>Blood stock</h1>
        <p class="muted">Stock changes automatically when donations are recorded and requests are approved.
            Use the form below only to correct the count (for example after a physical stock check, or when blood expires).</p>
    </div>

    <div class="table-wrap">
        <table>
            <thead><tr><th>Blood group</th><th>Units</th><th>Level</th><th>Last updated</th><th>Set exact units</th></tr></thead>
            <tbody>
            <c:forEach var="s" items="${stock}">
                <tr>
                    <td><span class="badge badge-group"><c:out value="${s.bloodGroup}"/></span></td>
                    <td><strong><c:out value="${s.units}"/></strong></td>
                    <td style="min-width:160px">
                        <div class="bar" style="margin:4px 0"><span class="${s.level}" style="width:${s.percent}%"></span></div>
                        <span class="badge badge-${s.level}"><c:out value="${s.level}"/></span>
                    </td>
                    <td><fmt:formatDate value="${s.updatedOn}" pattern="dd MMM yyyy, HH:mm"/></td>
                    <td>
                        <form action="${ctx}/admin/stock" method="post" class="inline-form">
                            <input type="hidden" name="csrf" value="${sessionScope.csrf}">
                            <input type="hidden" name="bloodGroup" value="${s.bloodGroup}">
                            <input type="number" name="units" min="0" max="9999" value="${s.units}" required style="width:90px">
                            <button type="submit" class="btn btn-sm btn-outline">Update</button>
                        </form>
                    </td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
